import { SlashCommandBuilder } from '@discordjs/builders';
import { ComponentHandlerFn, type Command, type ChatInputHandlerFn } from '.';

/**
 * Simple wrapper around the SlashCommandBuilder provided by Discord.js
 */
export class CommandBuilder extends SlashCommandBuilder {
  private _handler: ChatInputHandlerFn;
  private _componentsHandler: Record<string, ComponentHandlerFn> = {};

  setChatInputHandler(handler: ChatInputHandlerFn): this {
    this._handler = handler;
    return this;
  }

  addComponentHandler(name: string, handler: ComponentHandlerFn): this {
    this._componentsHandler[name] = handler;
    return this;
  }

  build(): Command {
    return {
      json: this.toJSON(),
      chatInputHandler: this._handler,
      componentHandlers: this._componentsHandler,
    };
  }
}
