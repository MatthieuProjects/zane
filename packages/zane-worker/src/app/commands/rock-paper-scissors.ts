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

type Response = 'rock' | 'paper' | 'scissors';
type State = { players: [string, string]; responses: Response[] };
const states: Record<string, State> = {};

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
        content: ctx.t('rock-paper-scissors:cantPlayWithYourself'),
        flags: MessageFlags.Ephemeral,
      },
    };
  }

  const gameId = ((Math.random() * 0xffffff) << 0)
    .toString(16)
    .padStart(6, '0');
  states[gameId] = { players: [opponent1.id, opponent2.id], responses: [] };

  return {
    type: InteractionResponseType.ChannelMessageWithSource,
    data: {
      content: `<@${opponent1.id}> <@${opponent2.id}>`,
      embeds: [
        {
          title: ctx.t('rock-paper-scissors:embed.title'),
          description: ctx.t('rock-paper-scissors:embed.description'),
        },
      ],
      components: [
        {
          type: ComponentType.ActionRow,
          components: [
            {
              type: ComponentType.StringSelect,
              custom_id: createCustomId('input', gameId),

              options: [
                {
                  label: `🪨 ${ctx.t('rock-paper-scissors:items.rock')}`,
                  value: 'rock',
                },
                {
                  label: `📰 ${ctx.t('rock-paper-scissors:items.paper')}`,
                  value: 'paper',
                },
                {
                  label: `✂️ ${ctx.t('rock-paper-scissors:items.scissors')}`,
                  value: 'scissors',
                },
              ],
            },
          ],
        },
      ],
    },
  };
};

const handleInput: ComponentHandlerFn = async (
  { createCustomId, ...event },
  gameId
): Promise<APIInteractionResponse> => {
  const ctx = i18next.cloneInstance();
  ctx.changeLanguage(event.locale);

  const game = states[gameId];

  const user = event.user || event.member.user;
  if (
    !game ||
    event.data.component_type !== ComponentType.StringSelect ||
    event.data.values.length !== 1 ||
    !game.players.includes(user.id) ||
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

  const response = event.data.values[0] as Response;
  const playerId = game.players.indexOf(user.id);

  if (game.responses[playerId]) {
    return {
      type: InteractionResponseType.ChannelMessageWithSource,
      data: {
        content: ctx.t('rock-paper-scissors:alreadyResponded'),
        flags: MessageFlags.Ephemeral,
      },
    };
  }

  game.responses[playerId] = response;

  if (game.responses[0] === undefined || game.responses[1] === undefined) {
    states[gameId] = game;
    return {
      type: InteractionResponseType.ChannelMessageWithSource,
      data: {
        content: ctx.t('rock-paper-scissors:waitingForOpponent'),
        flags: MessageFlags.Ephemeral,
      },
    };
  } else {
    let message: string;

    if (game.responses[0] === game.responses[1]) {
      message = ctx.t('rock-paper-scissors:tieMessage', {
        response: `$t(rock-paper-scissors:items.${game.responses[0]})`,
      });
    } else if (
      (game.responses[0] === 'paper' && game.responses[1] === 'scissors') ||
      (game.responses[0] === 'rock' && game.responses[1] === 'paper') ||
      (game.responses[0] === 'scissors' && game.responses[1] === 'rock')
    ) {
      message = ctx.t('rock-paper-scissors:wonMessage', {
        userId: game.players[1],
        otherUser: game.players[0],
        otherResponse: `$t(rock-paper-scissors:items.${game.responses[0]})`,
      });
    } else {
      message = ctx.t('rock-paper-scissors:wonMessage', {
        userId: game.players[0],
        otherUser: game.players[1],
        otherResponse: `$t(rock-paper-scissors:items.${game.responses[1]})`,
      });
    }

    delete states[gameId];
    return {
      type: InteractionResponseType.ChannelMessageWithSource,
      data: {
        content: message,
      },
    };
  }
};

i18next.loadNamespaces(['rock-paper-scissors']);

export const rockPaperScisors = new CommandBuilder()
  .setChatInputHandler(handler)
  .addComponentHandler('input', handleInput)
  .setName('rock-paper-scissors')
  .setNameLocalizations(generateLanguageMap('rock-paper-scissors:name'))
  .setDescription(i18next.t('rock-paper-scissors:description'))
  .setDescriptionLocalizations(
    generateLanguageMap('rock-paper-scissors:description')
  )
  .addUserOption((option) =>
    option
      .setName('opponent')
      .setDescription(
        i18next.t('rock-paper-scissors:fields.opponent.description')
      )
      .setNameLocalizations(
        generateLanguageMap('rock-paper-scissors:fields.opponent.name')
      )
      .setDescriptionLocalizations(
        generateLanguageMap('rock-paper-scissors:fields.opponent.description')
      )
      .setRequired(true)
  )
  .addIntegerOption((option) =>
    option
      .setName('rounds')
      .setDescription(
        i18next.t('rock-paper-scissors:fields.rounds.description')
      )
      .setNameLocalizations(
        generateLanguageMap('rock-paper-scissors:fields.rounds.name')
      )
      .setDescriptionLocalizations(
        generateLanguageMap('rock-paper-scissors:fields.rounds.description')
      )
      .setMinValue(1)
      .setMaxValue(5)
  )
  .build();
