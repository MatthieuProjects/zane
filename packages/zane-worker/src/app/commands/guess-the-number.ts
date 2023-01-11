import {
  CommandBuilder,
  ChatInputHandlerFn,
  ComponentHandlerFn,
} from '@zane/nova-client';
import { generateLanguageMap } from '../utils';
import {
  APIInteractionDataResolved,
  APIInteractionResponse,
  ApplicationCommandOptionType,
  ComponentType,
  InteractionResponseType,
  MessageFlags,
} from 'discord-api-types/v10';
import i18next from 'i18next';

const handler: ChatInputHandlerFn = async ({
  createCustomId,
  ...event
}): Promise<APIInteractionResponse> => {
  const ctx = i18next.cloneInstance();
  ctx.changeLanguage(event.locale);

  const opponent1 = event.user || event.member.user;
  const opponentOption = event.data.options.find(
    ({ name }) => name === 'opponent'
  );
  if (opponentOption.type !== ApplicationCommandOptionType.User) return;
  const opponent2 = (event.data.resolved as APIInteractionDataResolved).users[
    opponentOption.value
  ];

  if (opponent1.id === opponent2.id) {
    return {
      type: InteractionResponseType.ChannelMessageWithSource,
      data: {
        content: ctx.t('guess-the-number:cantPlayWithYourself'),
        flags: MessageFlags.Ephemeral,
      },
    };
  }

  // Allocate a gameid
  const gameId = `${event.channel_id}${((Math.random() * 0xffffff) << 0)
    .toString(16)
    .padStart(6, '0')}`;

  // Allocate a worker
  const state = await event.client.nats.request(
    'zane.matchmake.initialize',
    Buffer.from(
      JSON.stringify({
        game_id: gameId,
        game_type: 'guess-the-number',
        users: [opponent1.id, opponent2.id],
      })
    )
  );

  const stateJSON = JSON.parse(state.data.toString());

  return {
    type: InteractionResponseType.ChannelMessageWithSource,
    data: {
      content: `<@${opponent1.id}> <@${opponent2.id}>`,
      embeds: [
        {
          title: ctx.t('guess-the-number:embed.title'),
          description: ctx.t('guess-the-number:embed.description'),
        },
      ],
      components: [
        {
          type: ComponentType.ActionRow,
          components: [
            {
              type: ComponentType.StringSelect,
              custom_id: createCustomId(stateJSON.status, gameId),

              options: [...Array(10)].map((_, i) => ({
                label: `${i + 1}`,
                value: `${i + 1}`,
              })),
            },
          ],
        },
      ],
    },
  };
};

const handleNumberSelection: ComponentHandlerFn = async (
  { createCustomId, ...event },
  gameId
): Promise<APIInteractionResponse> => {
  const ctx = i18next.cloneInstance();
  ctx.changeLanguage(event.locale);

  const user = event.user || event.member.user;
  if (
    event.data.component_type !== ComponentType.StringSelect ||
    event.data.values.length !== 1 ||
    !user
  ) {
    return {
      type: InteractionResponseType.ChannelMessageWithSource,
      data: {
        content: ctx.t('runtimeError'),
        flags: MessageFlags.Ephemeral,
      },
    };
  }

  const response = event.data.values[0];

  const state = await event.client.nats.request(
    'zane.game.' + gameId,
    Buffer.from(
      JSON.stringify({
        properties: {
          number: response,
        },
        user: user.id,
      })
    )
  );
  const stateJSON = JSON.parse(state.data.toString());

  if (stateJSON.status === 'waiting_for_number') {
    return {
      type: InteractionResponseType.ChannelMessageWithSource,
      data: {
        content: 'waiting for other user',
        flags: MessageFlags.Ephemeral,
      },
    };
  } else {
    return {
      type: InteractionResponseType.UpdateMessage,
      data: {
        content: 'done waiting',
        components: [
          {
            type: ComponentType.ActionRow,
            components: [
              {
                type: ComponentType.StringSelect,
                custom_id: createCustomId(stateJSON.status, gameId),

                options: [...Array(10)].map((_, i) => ({
                  label: `${i + 1}`,
                  value: `${i + 1}`,
                })),
              },
            ],
          },
        ],
        embeds: [],
      },
    };
  }
};

const handleNumberGuess: ComponentHandlerFn = async (
  { createCustomId, ...event },
  gameId
): Promise<APIInteractionResponse> => {
  const ctx = i18next.cloneInstance();
  ctx.changeLanguage(event.locale);

  const user = event.user || event.member.user;
  if (
    event.data.component_type !== ComponentType.StringSelect ||
    event.data.values.length !== 1 ||
    !user
  ) {
    return {
      type: InteractionResponseType.ChannelMessageWithSource,
      data: {
        content: ctx.t('runtimeError'),
        flags: MessageFlags.Ephemeral,
      },
    };
  }

  const response = event.data.values[0];

  const state = await event.client.nats.request(
    'zane.game.' + gameId,
    Buffer.from(
      JSON.stringify({
        properties: {
          number: response,
        },
        user: user.id,
      })
    )
  );
  const stateJSON = JSON.parse(state.data.toString());

  if (stateJSON.status === 'waiting_for_guesses') {
    return {
      type: InteractionResponseType.ChannelMessageWithSource,
      data: {
        content: 'waiting for other user',
        flags: MessageFlags.Ephemeral,
      },
    };
  } else {
    return {
      type: InteractionResponseType.UpdateMessage,
      data: {
        content: JSON.stringify(stateJSON),
        components: [],
        embeds: [],
      },
    };
  }
};

i18next.loadNamespaces(['guess-the-number']);

export const guessTheNumber = new CommandBuilder()
  .setChatInputHandler(handler)
  .addComponentHandler('waiting_for_number', handleNumberSelection)
  .addComponentHandler('waiting_for_guesses', handleNumberGuess)
  .setName('guess-the-number')
  .setNameLocalizations(generateLanguageMap('guess-the-number:name'))
  .setDescription(i18next.t('guess-the-number:description'))
  .setDescriptionLocalizations(
    generateLanguageMap('guess-the-number:description')
  )
  .addUserOption((option) =>
    option
      .setName('opponent')
      .setDescription(
        i18next.t('guess-the-numbers:fields.opponent.description')
      )
      /*.setNameLocalizations(
        generateLanguageMap('guess-the-number:fields.opponent.name')
      )
      .setDescriptionLocalizations(
        generateLanguageMap('guess-the-number:fields.opponent.description')
      )*/
      .setRequired(true)
  )
  .build();
