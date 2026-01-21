import { Module } from '@nestjs/common';
import { ChatController } from './chat.controller';
import { ChatsService as ChatService } from './chat.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from 'src/core/entities/user.entity';
import { Message } from 'src/core/entities/message.entity';
import { ChatUseCases } from './chat.usecase';
import { MeetingModule } from '../meeting/meeting.module';
import { UserModule } from '../user/user.module';
import { AuthModule } from '../auth/auth.module';
import { EventsModule } from 'src/events/events.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Message]),
    EventsModule,
    MeetingModule,
    UserModule,
    AuthModule,
  ],
  controllers: [ChatController],
  providers: [ChatService, ChatUseCases],
  exports: [ChatService, ChatUseCases],
})
export class ChatModule { }
