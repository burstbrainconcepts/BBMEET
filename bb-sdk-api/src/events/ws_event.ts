export class WsEvent {
    // ====== Room Events ======
    static roomPublish = 'room.publish';
    static roomSubscribe = 'room.subscribe';
    static roomAnswerSubscriber = 'room.answer_subscriber';
    static roomLeave = 'room.leave';
    static roomReconnect = 'room.reconnect';
    static roomMigrate = 'room.migrate';

    // ====== Room Renegotiation Events ======
    static roomPublisherRenegotiation = 'room.publisher_renegotiation';
    static roomSubscriberRenegotiation = 'room.subscriber_renegotiation';

    // ====== ICE Candidate Events ======
    static roomPublisherCandidate = 'room.publisher_candidate';
    static roomSubscriberCandidate = 'room.subscriber_candidate';

    // ====== Participant Presence Events ======
    static roomNewParticipant = 'room.new_participant';
    static roomParticipantLeft = 'room.participant_left';

    // ====== Media Controls Events ======
    static roomVideoEnabled = 'room.video_enabled';
    static roomCameraType = 'room.camera_type';
    static roomAudioEnabled = 'room.audio_enabled';
    static roomScreenSharing = 'room.screen_sharing';
    static roomHandRaising = 'room.hand_raising';
    static roomSubtitleTrack = 'room.subscribe_subtitle';

    // ====== Chat Events ======
    static chatSend = 'chat.send';
    static chatUpdate = 'chat.update';
    static chatDelete = 'chat.delete';

    // ====== System Events ======
    static systemDestroy = 'system.destroy';
}
