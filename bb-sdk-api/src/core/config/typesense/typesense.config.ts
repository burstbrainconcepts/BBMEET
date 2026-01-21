// typesense.config.ts

import { Injectable, Logger } from '@nestjs/common';
import { Client } from 'typesense';
import { EnvironmentConfigService } from '../environment/environments';

@Injectable()
export class TypesenseConfig {
  constructor(private readonly environment: EnvironmentConfigService) { }

  private readonly logger: Logger = new Logger(TypesenseConfig.name);

  async createSchema() {
    const client = this.getClient();

    try {
      try {
        await client.collections('users').delete();
      } catch (error) {
        // Ignore delete error if collection doesn't exist or connection fails
      }

      await client.collections().create({
        name: 'users',
        fields: [
          {
            name: 'id',
            type: 'int32',
            facet: false,
          },
          {
            name: 'userName',
            type: 'string',
            facet: false,
          },
          {
            name: 'fullName',
            type: 'string',
            facet: false,
          },
          {
            name: 'avatar',
            type: 'string',
            facet: false,
            optional: true,
          },
        ],
      });
    } catch (error) {
      this.logger.warn(
        `Typesense schema creation failed. Search functionality will be disabled. Error: ${error.message}`,
      );
    }
  }

  getClient(): Client {
    const client = new Client({
      apiKey: this.environment.getTypesenseApiKey(),
      nodes: [
        {
          host: this.environment.getTypesenseHost(),
          port: this.environment.getTypesensePort(),
          protocol: 'http',
        },
      ],
    });

    return client;
  }
}
