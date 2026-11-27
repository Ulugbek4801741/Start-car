const express = require('express');
const cors = require('cors');
const http = require('http');
const { WebSocketServer } = require('ws');
const crypto = require('crypto');

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '32kb' }));

const server = http.createServer(app);
const wss = new WebSocketServer({ noServer: true });
const rooms = new Map();

function roomFor(id) {
  if (!rooms.has(id)) rooms.set(id, { id, players: new Map(), startedAt: Date.now() });
  return rooms.get(id);
}
function publicRoom(room) {
  return { roomId: room.id, players: [...room.players.values()].map(p => ({
    id: p.id, name: p.name, car: p.car, color: p.color,
    x: p.x, speed: p.speed, steer: p.steer, progress: p.progress, updatedAt: p.updatedAt
  })) };
}
function broadcast(room) {
  const payload = JSON.stringify({ type: 'room_state', ...publicRoom(room) });
  for (const client of wss.clients) {
    if (client.readyState === 1 && client.roomId === room.id) client.send(payload);
  }
}
app.get('/api/health', (_req, res) => res.json({
  ok: true, service: 'START-CAR Race Server', version: '1.0.0',
  websocket: true, rooms: rooms.size, players: [...rooms.values()].reduce((n, r) => n + r.players.size, 0)
}));
app.get('/api/race/:roomId', (req, res) => {
  const room = roomFor(String(req.params.roomId).slice(0, 48));
  res.json({ ok: true, ...publicRoom(room) });
});
server.on('upgrade', (req, socket, head) => {
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname !== '/ws') return socket.destroy();
  wss.handleUpgrade(req, socket, head, ws => wss.emit('connection', ws, req, url));
});
wss.on('connection', (ws, _req, url) => {
  const roomId = (url.searchParams.get('room') || 'public').slice(0, 48);
  const room = roomFor(roomId);
  const playerId = crypto.randomUUID();
  ws.roomId = roomId;
  ws.playerId = playerId;
  room.players.set(playerId, {
    id: playerId, name: 'Poygachi', car: 'BMW M4 Competition', color: '#287be8',
    x: 0, speed: 0, steer: 0, progress: 0, updatedAt: Date.now()
  });
  ws.send(JSON.stringify({ type: 'welcome', playerId, roomId }));
  broadcast(room);
  ws.on('message', raw => {
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return; }
    const player = room.players.get(playerId);
    if (!player || !msg || typeof msg !== 'object') return;
    if (msg.type === 'profile') {
      if (typeof msg.name === 'string') player.name = msg.name.slice(0, 24);
      if (typeof msg.car === 'string') player.car = msg.car.slice(0, 64);
      if (typeof msg.color === 'string' && /^#[0-9a-f]{6}$/i.test(msg.color)) player.color = msg.color;
    }
    if (msg.type === 'input') {
      player.steer = Math.max(-1, Math.min(1, Number(msg.steer) || 0));
      player.speed = Math.max(0, Math.min(500, Number(msg.speed) || 0));
      player.x = Math.max(-1, Math.min(1, Number(msg.x) || 0));
      player.progress = Math.max(0, Number(msg.progress) || 0);
      player.updatedAt = Date.now();
    }
    broadcast(room);
  });
  ws.on('close', () => {
    room.players.delete(playerId);
    broadcast(room);
    if (room.players.size === 0) rooms.delete(roomId);
  });
});
const port = Number(process.env.PORT || 10000);
server.listen(port, '0.0.0.0', () => console.log('START-CAR race server listening on ' + port));
