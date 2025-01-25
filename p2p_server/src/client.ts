import { Socket } from './types.ts'
import { generateUniqueCode, serializeMessage } from './utils.ts'
import { Lobby } from './lobby.ts'
import { ClientSend } from './types.ts'

const clients = new Map<string, Client>()

const sendMessage =
	(socket: Socket, code: string): ClientSend => (message, sendType, from) => {
		return new Promise<void>((resolve, reject) => {
			if (typeof message !== 'string') {
				message = serializeMessage(message)
			}
			if (!message.endsWith('\n')) {
				message += '\n'
			}
			if (from) {
				console.log(
					`${new Date().toISOString()} :: ${
						sendType ?? 'Sending'
					} :: ${from}->${code} :: ${message}`,
				)
			} else {
				console.log(
					`${new Date().toISOString()} :: ${
						sendType ?? 'Sending'
					} :: ${code} :: ${message}`,
				)
			}
			socket.write(message, (err) => {
				if (err) {
					console.error('Error sending message:', err)
					reject(err)
				} else {
					socket.uncork()
					resolve()
				}
			})
		})
	}

export class Client {
	private code: string
	private state: 'connecting' | 'connected'
	private username?: string
	private currentLobby?: Lobby | null

	public send: ClientSend

	static getClientFromCode(code: string) {
		return clients.get(code)
	}

	constructor(socket: Socket) {
		this.code = generateUniqueCode()
		this.send = sendMessage(socket, this.code)
		this.state = 'connecting'
		this.currentLobby = null
		clients.set(this.code, this)
	}

	getCode() {
		return this.code
	}

	setConnected(username: string): asserts this is ConnectedClient {
		this.state = 'connected'
		this.username = username
	}

	isConnected(): this is ConnectedClient {
		return this.state === 'connected'
	}

	setUsername(username: string) {
		this.username = username
	}

	getUsername(): string | undefined {
		return this.username
	}

	joinLobby(lobby: Lobby) {
		this.currentLobby = lobby
	}

	leaveLobby() {
		if (this.currentLobby) {
			this.currentLobby.removeClient(this)
			this.currentLobby = null
		}
	}

	getCurrentLobby(): Lobby | null | undefined {
		return this.currentLobby
	}

	isHost(): boolean {
		return this.currentLobby?.getHost()?.getCode() === this.code
	}

	delete() {
		this.leaveLobby()
		clients.delete(this.code)
	}
}

export interface ConnectedClient extends Client {
	_state: 'connected'
	_username: string
	_currentLobby: Lobby | null
	getUsername(): string
	getCurrentLobby(): Lobby | null
}
