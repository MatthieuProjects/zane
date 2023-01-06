import { CommandBuilder, HandlerFn } from '@zane/nova-client';
import { generateLanguageMap } from '../utils';
import {
  APIInteractionResponse,
  InteractionResponseType,
} from 'discord-api-types/v10';
import i18next from 'i18next';

const handler: HandlerFn = async (event): Promise<APIInteractionResponse> => {
  const ctx = i18next.cloneInstance();
  ctx.changeLanguage(event.locale);

  return {
    type: InteractionResponseType.ChannelMessageWithSource,
    data: {
      content: ctx.t('not-available'),
    },
  };
};
i18next.loadNamespaces(['rock-paper-scissors']);

export const rockPaperScisors = new CommandBuilder()
  .handler(handler)
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
      .setDescription(i18next.t('rock-paper-scissors:fields.rounds.description'))
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
