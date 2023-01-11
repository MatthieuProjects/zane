import './i18n';
import {
  Client,
  Command,
  buildHandler,
  registerCommands,
} from '@zane/nova-client';
import { APIUser, Routes } from 'discord-api-types/v10';
import { guessTheNumber } from './commands';
import { Logger, createLogger, format, transports } from 'winston';
import { environment } from '../environments/environment.prod';

export class Zane extends Client {
  private commands: Command[] = [guessTheNumber];
  public logger: Logger = createLogger({
    level: environment.production ? 'info' : 'debug',
    transports: [new transports.Console({ format: format.colorize() })],
  });

  constructor() {
    const nats = process.env.NATS || 'localhost';
    const api = process.env.API || 'http://localhost:8090/api';

    super({
      transport: { queue: 'zane-worker', nats: { servers: [nats] } },
      rest: {
        api,
      },
    });

    this.on('interactionCreate', buildHandler(this.commands));
  }

  public async register() {
    return await registerCommands(
      this.commands,
      this.rest,
      ((await this.rest.get(Routes.user('@me'))) as APIUser).id
    );
  }
}
