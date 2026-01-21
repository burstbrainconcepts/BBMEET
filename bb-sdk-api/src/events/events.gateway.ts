import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { WsEvent } from './ws_event';

@WebSocketGateway({
  path: '/socket.io',
  transports: ['websocket', 'polling'],
  cors: {
    origin: '*',
  },
})
export class EventsGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private logger: Logger = new Logger('EventsGateway');

  // Map socketId to Participant info
  private socketToParticipant: Map<string, { id: number; roomId: string }> = new Map();

  constructor() {
    this.logger.log('EventsGateway Constructor Called');
  }

  afterInit(server: Server) {
    this.logger.log('Socket.IO Gateway Initialized');
  }

  handleDisconnect(client: Socket) {
    const info = this.socketToParticipant.get(client.id);
    if (info) {
      this.logger.log(`Client disconnected: ${client.id} (Participant: ${info.id})`);
      this.server.to(info.roomId).emit(WsEvent.roomParticipantLeft, {
        targetId: info.id,
      });
      this.socketToParticipant.delete(client.id);
    } else {
      this.logger.log(`Client disconnected: ${client.id}`);
    }
  }

  handleConnection(client: Socket, ...args: any[]) {
    this.logger.log(`Client connected: ${client.id}`);
    // Future: Verify Token here
  }

  // ====== Public Methods ======
  emit(roomId: string, event: string, data: any) {
    this.server.to(roomId).emit(event, data);
  }

  // ====== Room Events ======
  @SubscribeMessage(WsEvent.roomPublish)
  handleRoomJoin(client: Socket, payload: any) {
    // payload: { roomId, participant: { id, ... }, ... }

    // Defensive coding: assume roomId might be in payload or we need to extract it.
    // Given the SDK sends payload.toJson(), we check for roomId.
    if (payload.participant && payload.participant.id) {
      const roomId = payload.roomId;
      if (roomId) {
        client.join(roomId);
        this.socketToParticipant.set(client.id, { id: payload.participant.id, roomId: roomId });

        client.broadcast.to(roomId).emit(WsEvent.roomNewParticipant, {
          participant: payload.participant,
          isMigrate: false,
        });
      }
    }
  }

  @SubscribeMessage(WsEvent.roomLeave)
  handleRoomLeave(client: Socket, payload: any) {
    if (payload.roomId) {
      client.leave(payload.roomId);
      const info = this.socketToParticipant.get(client.id);
      if (info) {
        client.broadcast.to(payload.roomId).emit(WsEvent.roomParticipantLeft, {
          targetId: info.id,
        });
        this.socketToParticipant.delete(client.id);
      }
    }
  }

  // ====== Signaling (Broadcasting) ======

  @SubscribeMessage(WsEvent.roomAnswerSubscriber)
  handleAnswerSubscriber(client: Socket, payload: any) {
    if (payload.roomId) {
      client.broadcast.to(payload.roomId).emit(WsEvent.roomAnswerSubscriber, payload);
    }
  }

  @SubscribeMessage(WsEvent.roomPublisherCandidate)
  handlePublisherCandidate(client: Socket, payload: any) {
    if (payload.roomId) {
      client.broadcast.to(payload.roomId).emit(WsEvent.roomPublisherCandidate, payload);
    }
  }

  @SubscribeMessage(WsEvent.roomSubscriberCandidate)
  handleSubscriberCandidate(client: Socket, payload: any) {
    if (payload.roomId) {
      client.broadcast.to(payload.roomId).emit(WsEvent.roomSubscriberCandidate, payload);
    }
  }

  @SubscribeMessage(WsEvent.roomPublisherRenegotiation)
  handlePublisherRenegotiation(client: Socket, payload: any) {
    if (payload.roomId) {
      client.broadcast.to(payload.roomId).emit(WsEvent.roomPublisherRenegotiation, payload);
    }
  }

  @SubscribeMessage(WsEvent.roomSubscriberRenegotiation)
  handleSubscriberRenegotiation(client: Socket, payload: any) {
    if (payload.roomId) {
      client.broadcast.to(payload.roomId).emit(WsEvent.roomSubscriberRenegotiation, payload);
    }
  }

  // ====== Media Controls ======

  private emitMediaEvent(client: Socket, event: string, payload: any) {
    const info = this.socketToParticipant.get(client.id);
    if (info) {
      const enrichedPayload = { ...payload, participantId: info.id };
      client.broadcast.to(info.roomId).emit(event, enrichedPayload);
    }
  }

  @SubscribeMessage(WsEvent.roomVideoEnabled)
  handleVideoEnabled(client: Socket, payload: any) {
    this.emitMediaEvent(client, WsEvent.roomVideoEnabled, payload);
  }

  @SubscribeMessage(WsEvent.roomAudioEnabled)
  handleAudioEnabled(client: Socket, payload: any) {
    this.emitMediaEvent(client, WsEvent.roomAudioEnabled, payload);
  }

  @SubscribeMessage(WsEvent.roomCameraType)
  handleCameraType(client: Socket, payload: any) {
    this.emitMediaEvent(client, WsEvent.roomCameraType, payload);
  }

  @SubscribeMessage(WsEvent.roomScreenSharing)
  handleScreenSharing(client: Socket, payload: any) {
    this.emitMediaEvent(client, WsEvent.roomScreenSharing, payload);
  }

  @SubscribeMessage(WsEvent.roomHandRaising)
  handleHandRaising(client: Socket, payload: any) {
    this.emitMediaEvent(client, WsEvent.roomHandRaising, payload);
  }
}
