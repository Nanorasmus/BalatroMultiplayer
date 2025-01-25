import net from 'node:net'
import { ActionMessage, sendType, ToMessage } from './types.ts'
import { Client, ConnectedClient } from './client.ts'
import ActionHandler from './action_handler.ts'
import { parseMessage } from './utils.ts'

const PORT = 8788

const assertClientConnected = (client: Client): client is ConnectedClient => {
	if (!client.isConnected()) {
		client.send('action:error,message:Not finished connecting to the server', sendType.Error, "SERVER")
		return false
	}
	return true
}

const handleClientMessage = async (client: Client, data: string) => {
	const messages = data.toString().split('\n').filter((msg) => msg.length > 0)

	for (const message of messages) {
		if (!client) {
			console.log('Warning: Message received from unknown client')
			continue
		}

		console.log(`Received :: ${client.getCode()} :: ${message}`)

		const parsedMessage = parseMessage(message)

		if (typeof parsedMessage.action !== 'string') {
			await client.send('action:error,message:Message missing action', sendType.Error, "SERVER")
			continue
		}

		if (typeof(parsedMessage.to) === 'string' && typeof(parsedMessage.from) === 'string') {
			const toMessage = parsedMessage as ToMessage
			ActionHandler.sendTo(client, toMessage, toMessage.to)
			return
		}

		const actionMessage = parsedMessage as ActionMessage
		
		switch (actionMessage.action) {
			case 'keepAlive':
				await client.send('action:keepAlive_ack', sendType.Ack, "SERVER")
				break
			case 'connect':
				ActionHandler.connect(client, actionMessage)
				break
			case 'openLobby':
				if (assertClientConnected(client)) ActionHandler.openLobby(client)
				break
			case 'joinLobby':
				if (assertClientConnected(client)) {
					ActionHandler.joinLobby(client, actionMessage)
				}
				break
		}
	}
}

const server = net.createServer((socket) => {
	socket.setKeepAlive(true, 1000)
	socket.setNoDelay(true)

	const client = new Client(socket)

	let buffer = ''

	socket.on('data', (data) => {
		buffer += data.toString()

		const messages = buffer.split('\n')
		buffer = messages.pop() ?? ''

		if (messages.length > 0) {
			handleClientMessage(client, messages.join('\n'))
		}
	})

	socket.on('end', () => {
		client.delete()
	})

	socket.on('error', (err) => {
		if (!client) {
			console.error(`Error :: Unknown :: ${err.message}`)
			return
		}
		console.error(`Error :: ${client.getCode()} :: ${err.message}`)
		client.delete()
	})
})

if (import.meta.main) {
	server.listen(PORT, () => {
		console.log(`Server listening on port ${PORT}`)
	})
}
