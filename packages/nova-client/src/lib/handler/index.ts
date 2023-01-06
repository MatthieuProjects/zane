import { type REST } from '@discordjs/rest';
import {
  type APIInteraction,
  InteractionType,
  type RESTPostAPIApplicationCommandsJSONBody,
  type RESTPostAPIChatInputApplicationCommandsJSONBody,
  Routes,
  type APIInteractionResponse,
  APIChatInputApplicationCommandInteraction,
  ApplicationCommandType,
  APIMessageComponentInteraction,
} from 'discord-api-types/v10';

export * from './builder';

export type PromiseLike<T> = T | Promise<T>;
type WrappedUtils<T> = T & {
  createCustomId: (state: string, name: string) => string;
};
/**
 * A simple function that executes a slash command.
 */
export type ChatInputHandlerFn = (
  data: WrappedUtils<APIChatInputApplicationCommandInteraction>
) => PromiseLike<APIInteractionResponse>;

export type ComponentHandlerFn = (
  event: WrappedUtils<APIMessageComponentInteraction>,
  state: string
) => PromiseLike<APIInteractionResponse>;

export type Command = {
  json: RESTPostAPIChatInputApplicationCommandsJSONBody;
  chatInputHandler: ChatInputHandlerFn;
  componentHandlers: Record<string, ComponentHandlerFn>;
};

/**
 * Register all the commands to discord
 * @param commands List of commands to register
 * @param rest Rest api instance
 * @param applicationId Current application id
 */
export const registerCommands = async (
  commands: Iterable<Command>,
  rest: REST,
  appId: string
) => {
  await rest.put(Routes.applicationCommands(appId), {
    body: [...commands].map(
      (x) => x.json
    ) as RESTPostAPIApplicationCommandsJSONBody[],
  });
};

/**
 * Creates a new handler to handle the slash commands.
 * @param commands List of commands to handle
 * @returns Handler function
 */
export const buildHandler = (commands: Iterable<Command>) => {
  const internal = new Map<string, Command>();
  for (const command of commands) {
    internal.set(command.json.name, command);
  }

  return async (
    event: APIInteraction,
    reply?: (data: APIInteractionResponse) => void
  ) => {
    if (
      event.type === InteractionType.ApplicationCommand &&
      event.data.type === ApplicationCommandType.ChatInput
    ) {
      const command = internal.get(event.data.name);

      if (command) {
        const createCustomId = (name: string, state: string) =>
          `${event.data.name}$${name}#${state}`;
        const data = await command.chatInputHandler({
          ...event,
          createCustomId,
        } as WrappedUtils<APIChatInputApplicationCommandInteraction>);

        reply(data);
      }
    } else if (event.type === InteractionType.MessageComponent) {
      console.log('handling component event!', event.data.custom_id);
      let parsed = parseCustomId(event.data.custom_id);
      if (parsed) {
        const { command: commandName, name, state } = parsed;
        const command = internal.get(commandName);

        if (command && command.componentHandlers[name]) {
          const createCustomId = (name: string, state: string) =>
            `${commandName}$${name}#${state}`;
          const response = await command.componentHandlers[name](
            {
              ...event,
              createCustomId,
            },
            state
          );

          reply(response);
        }
      }
    }
  };
};

let parseCustomId = (
  customId: string
): { name: string; command: string; state: string } | null => {
  let customIdRegexpr = /(.+)\$(.+)\#(.+)/g;
  let parse = customIdRegexpr.exec(customId);

  if (parse) {
    let [, command, name, state] = parse;
    return { name, command, state };
  } else {
    console.log("failed parsing", customId, parse);
    return null;
  }
};
