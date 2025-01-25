import crypto from 'node:crypto'
import { ActionMessage, ParsedMessage, ToMessage } from './types.ts'
import { Lobby } from './lobby.ts'

export const generateUniqueCode = (): string => {
	let code
	do {
		code = crypto.randomBytes(3).toString('hex').toUpperCase()
	} while (Lobby.getLobby(code))
	return code
}

export const serializeMessage = (message: ActionMessage | ToMessage): string => {
	const message_parts = Object.entries(message).map(([key, value]) =>
		`${key.toString().replaceAll(",", "")}:${value.toString().replaceAll(",", "")}`
	)
	return message_parts.join(',')
}

export const parseMessage = (message: string): ParsedMessage => {
	const parts = message.split(',')
	const data: Record<string, string> = {}
	for (const part of parts) {
		const [key, value] = part.split(':')
		data[key.trim()] = value.trim()
	}
	return data
}
