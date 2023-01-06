import { Client } from '@zane/nova-client';

export class Zane extends Client {
  constructor() {
    super({
      transport: { queue: 'zane-worker', nats: { servers: ['localhost'] } },
    });

    this.on("messageCreate", async (message) => {
      console.log(message);
    });
  }
}
