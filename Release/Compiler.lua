---@diagnostic disable: undefined-global
local function _W(f)
	return f()
end
local bit = bit32

local gf = _W(function(_ENV, ...)
	local bxor = bit.bxor
	local lshift = bit.lshift

	local n = 0x100
	local ord = 0xff
	local irrPolynom = 0x11b
	local exp = {}
	local log = {}

	local function add(operand1, operand2)
		return bxor(operand1, operand2)
	end

	local function sub(operand1, operand2)
		return bxor(operand1, operand2)
	end

	local function invert(operand)
		if operand == 1 then
			return 1
		end
		local exponent = ord - log[operand]
		return exp[exponent]
	end

	local function mul(operand1, operand2)
		if operand1 == 0 or operand2 == 0 then
			return 0
		end

		local exponent = log[operand1] + log[operand2]
		if exponent >= ord then
			exponent = exponent - ord
		end
		return exp[exponent]
	end

	local function div(operand1, operand2)
		if operand1 == 0 then
			return 0
		end
		local exponent = log[operand1] - log[operand2]
		if exponent < 0 then
			exponent = exponent + ord
		end
		return exp[exponent]
	end

	local function printLog()
		for i = 1, n do
			print("log(", i - 1, ")=", log[i - 1])
		end
	end

	local function printExp()
		for i = 1, n do
			print("exp(", i - 1, ")=", exp[i - 1])
		end
	end

	local function initMulTable()
		local a = 1

		for i = 0, ord - 1 do
			exp[i] = a
			log[a] = i

			a = bxor(lshift(a, 1), a)
			if a > ord then
				a = sub(a, irrPolynom)
			end
		end
	end

	initMulTable()

	return {
		add = add,
		sub = sub,
		invert = invert,
		mul = mul,
		div = dib,
		printLog = printLog,
		printExp = printExp,
	}
end)
util = _W(function(_ENV, ...)
	local bxor = bit.bxor
	local rshift = bit.rshift
	local band = bit.band
	local lshift = bit.lshift

	local sleepCheckIn
	local function byteParity(byte)
		byte = bxor(byte, rshift(byte, 4))
		byte = bxor(byte, rshift(byte, 2))
		byte = bxor(byte, rshift(byte, 1))
		return band(byte, 1)
	end

	local function getByte(number, index)
		if index == 0 then
			return band(number, 0xff)
		else
			return band(rshift(number, index * 8), 0xff)
		end
	end

	local function putByte(number, index)
		if index == 0 then
			return band(number, 0xff)
		else
			return lshift(band(number, 0xff), index * 8)
		end
	end

	local function bytesToInts(bytes, start, n)
		local ints = {}
		for i = 0, n - 1 do
			ints[i + 1] = putByte(bytes[start + (i * 4)], 3)
				+ putByte(bytes[start + (i * 4) + 1], 2)
				+ putByte(bytes[start + (i * 4) + 2], 1)
				+ putByte(bytes[start + (i * 4) + 3], 0)

			if n % 10000 == 0 then
				sleepCheckIn()
			end
		end
		return ints
	end

	local function intsToBytes(ints, output, outputOffset, n)
		n = n or #ints
		for i = 0, n - 1 do
			for j = 0, 3 do
				output[outputOffset + i * 4 + (3 - j)] = getByte(ints[i + 1], j)
			end

			if n % 10000 == 0 then
				sleepCheckIn()
			end
		end
		return output
	end

	local function bytesToHex(bytes)
		local hexBytes = ""

		for i, byte in ipairs(bytes) do
			hexBytes = hexBytes .. string.format("%02x ", byte)
		end

		return hexBytes
	end

	local function hexToBytes(bytes)
		local out = {}
		for i = 1, #bytes, 2 do
			out[#out + 1] = tonumber(bytes:sub(i, i + 1), 16)
		end

		return out
	end

	local function toHexString(data)
		local type = type(data)
		if type == "number" then
			return string.format("%08x", data)
		elseif type == "table" then
			return bytesToHex(data)
		elseif type == "string" then
			local bytes = { string.byte(data, 1, #data) }

			return bytesToHex(bytes)
		else
			return data
		end
	end

	local function padByteString(data)
		local dataLength = #data

		local random1 = math.random(0, 255)
		local random2 = math.random(0, 255)

		local prefix = string.char(
			random1,
			random2,
			random1,
			random2,
			getByte(dataLength, 3),
			getByte(dataLength, 2),
			getByte(dataLength, 1),
			getByte(dataLength, 0)
		)

		data = prefix .. data

		local paddingLength = math.ceil(#data / 16) * 16 - #data
		local padding = ""
		for i = 1, paddingLength do
			padding = padding .. string.char(math.random(0, 255))
		end

		return data .. padding
	end

	local function properlyDecrypted(data)
		local random = { string.byte(data, 1, 4) }

		if random[1] == random[3] and random[2] == random[4] then
			return true
		end

		return false
	end

	local function unpadByteString(data)
		if not properlyDecrypted(data) then
			return nil
		end

		local dataLength = putByte(string.byte(data, 5), 3)
			+ putByte(string.byte(data, 6), 2)
			+ putByte(string.byte(data, 7), 1)
			+ putByte(string.byte(data, 8), 0)

		return string.sub(data, 9, 8 + dataLength)
	end

	local function xorIV(data, iv)
		for i = 1, 16 do
			data[i] = bxor(data[i], iv[i])
		end
	end

	local function increment(data)
		local i = 16
		while true do
			local value = data[i] + 1
			if value >= 256 then
				data[i] = value - 256
				i = (i - 2) % 16 + 1
			else
				data[i] = value
				break
			end
		end
	end

	local push, pull, time = os.queueEvent, coroutine.yield, os.time
	local oldTime = time()
	local function sleepCheckIn() end

	local function getRandomData(bytes)
		local char, random, sleep, insert = string.char, math.random, sleepCheckIn, table.insert
		local result = {}

		for i = 1, bytes do
			insert(result, random(0, 255))
			if i % 10240 == 0 then
				sleep()
			end
		end

		return result
	end

	local function getRandomString(bytes)
		local char, random, sleep, insert = string.char, math.random, sleepCheckIn, table.insert
		local result = {}

		for i = 1, bytes do
			insert(result, char(random(0, 255)))
			if i % 10240 == 0 then
				sleep()
			end
		end

		return table.concat(result)
	end

	return {
		byteParity = byteParity,
		getByte = getByte,
		putByte = putByte,
		bytesToInts = bytesToInts,
		intsToBytes = intsToBytes,
		bytesToHex = bytesToHex,
		hexToBytes = hexToBytes,
		toHexString = toHexString,
		padByteString = padByteString,
		properlyDecrypted = properlyDecrypted,
		unpadByteString = unpadByteString,
		xorIV = xorIV,
		increment = increment,

		sleepCheckIn = sleepCheckIn,

		getRandomData = getRandomData,
		getRandomString = getRandomString,
	}
end)
aes = _W(function(_ENV, ...)
	local putByte = util.putByte
	local getByte = util.getByte

	local ROUNDS = "rounds"
	local KEY_TYPE = "type"
	local ENCRYPTION_KEY = 1
	local DECRYPTION_KEY = 2

	local SBox = {}
	local iSBox = {}

	local table0 = {}
	local table1 = {}
	local table2 = {}
	local table3 = {}

	local tableInv0 = {}
	local tableInv1 = {}
	local tableInv2 = {}
	local tableInv3 = {}

	local rCon = {
		0x01000000,
		0x02000000,
		0x04000000,
		0x08000000,
		0x10000000,
		0x20000000,
		0x40000000,
		0x80000000,
		0x1b000000,
		0x36000000,
		0x6c000000,
		0xd8000000,
		0xab000000,
		0x4d000000,
		0x9a000000,
		0x2f000000,
	}

	local function affinMap(byte)
		mask = 0xf8
		result = 0
		for i = 1, 8 do
			result = bit.lshift(result, 1)

			parity = util.byteParity(bit.band(byte, mask))
			result = result + parity

			lastbit = bit.band(mask, 1)
			mask = bit.band(bit.rshift(mask, 1), 0xff)
			if lastbit ~= 0 then
				mask = bit.bor(mask, 0x80)
			else
				mask = bit.band(mask, 0x7f)
			end
		end

		return bit.bxor(result, 0x63)
	end

	local function calcSBox()
		for i = 0, 255 do
			if i ~= 0 then
				inverse = gf.invert(i)
			else
				inverse = i
			end
			mapped = affinMap(inverse)
			SBox[i] = mapped
			iSBox[mapped] = i
		end
	end

	local function calcRoundTables()
		for x = 0, 255 do
			byte = SBox[x]
			table0[x] = putByte(gf.mul(0x03, byte), 0)
				+ putByte(byte, 1)
				+ putByte(byte, 2)
				+ putByte(gf.mul(0x02, byte), 3)
			table1[x] = putByte(byte, 0)
				+ putByte(byte, 1)
				+ putByte(gf.mul(0x02, byte), 2)
				+ putByte(gf.mul(0x03, byte), 3)
			table2[x] = putByte(byte, 0)
				+ putByte(gf.mul(0x02, byte), 1)
				+ putByte(gf.mul(0x03, byte), 2)
				+ putByte(byte, 3)
			table3[x] = putByte(gf.mul(0x02, byte), 0)
				+ putByte(gf.mul(0x03, byte), 1)
				+ putByte(byte, 2)
				+ putByte(byte, 3)
		end
	end

	local function calcInvRoundTables()
		for x = 0, 255 do
			byte = iSBox[x]
			tableInv0[x] = putByte(gf.mul(0x0b, byte), 0)
				+ putByte(gf.mul(0x0d, byte), 1)
				+ putByte(gf.mul(0x09, byte), 2)
				+ putByte(gf.mul(0x0e, byte), 3)
			tableInv1[x] = putByte(gf.mul(0x0d, byte), 0)
				+ putByte(gf.mul(0x09, byte), 1)
				+ putByte(gf.mul(0x0e, byte), 2)
				+ putByte(gf.mul(0x0b, byte), 3)
			tableInv2[x] = putByte(gf.mul(0x09, byte), 0)
				+ putByte(gf.mul(0x0e, byte), 1)
				+ putByte(gf.mul(0x0b, byte), 2)
				+ putByte(gf.mul(0x0d, byte), 3)
			tableInv3[x] = putByte(gf.mul(0x0e, byte), 0)
				+ putByte(gf.mul(0x0b, byte), 1)
				+ putByte(gf.mul(0x0d, byte), 2)
				+ putByte(gf.mul(0x09, byte), 3)
		end
	end

	local function rotWord(word)
		local tmp = bit.band(word, 0xff000000)
		return (bit.lshift(word, 8) + bit.rshift(tmp, 24))
	end

	local function subWord(word)
		return putByte(SBox[getByte(word, 0)], 0)
			+ putByte(SBox[getByte(word, 1)], 1)
			+ putByte(SBox[getByte(word, 2)], 2)
			+ putByte(SBox[getByte(word, 3)], 3)
	end

	local function expandEncryptionKey(key)
		local keySchedule = {}
		local keyWords = math.floor(#key / 4)

		if (keyWords ~= 4 and keyWords ~= 6 and keyWords ~= 8) or (keyWords * 4 ~= #key) then
			warn("Invalid key size: " .. tostring(keyWords))
			return nil
		end

		keySchedule[ROUNDS] = keyWords + 6
		keySchedule[KEY_TYPE] = ENCRYPTION_KEY

		for i = 0, keyWords - 1 do
			keySchedule[i] = putByte(key[i * 4 + 1], 3)
				+ putByte(key[i * 4 + 2], 2)
				+ putByte(key[i * 4 + 3], 1)
				+ putByte(key[i * 4 + 4], 0)
		end

		for i = keyWords, (keySchedule[ROUNDS] + 1) * 4 - 1 do
			local tmp = keySchedule[i - 1]

			if i % keyWords == 0 then
				tmp = rotWord(tmp)
				tmp = subWord(tmp)

				local index = math.floor(i / keyWords)
				tmp = bit.bxor(tmp, rCon[index])
			elseif keyWords > 6 and i % keyWords == 4 then
				tmp = subWord(tmp)
			end

			keySchedule[i] = bit.bxor(keySchedule[(i - keyWords)], tmp)
		end

		return keySchedule
	end

	local function invMixColumnOld(word)
		local b0 = getByte(word, 3)
		local b1 = getByte(word, 2)
		local b2 = getByte(word, 1)
		local b3 = getByte(word, 0)

		return putByte(
			gf.add(gf.add(gf.add(gf.mul(0x0b, b1), gf.mul(0x0d, b2)), gf.mul(0x09, b3)), gf.mul(0x0e, b0)),
			3
		) + putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b2), gf.mul(0x0d, b3)), gf.mul(0x09, b0)), gf.mul(0x0e, b1)), 2) + putByte(
			gf.add(gf.add(gf.add(gf.mul(0x0b, b3), gf.mul(0x0d, b0)), gf.mul(0x09, b1)), gf.mul(0x0e, b2)),
			1
		) + putByte(gf.add(gf.add(gf.add(gf.mul(0x0b, b0), gf.mul(0x0d, b1)), gf.mul(0x09, b2)), gf.mul(0x0e, b3)), 0)
	end

	local function invMixColumn(word)
		local b0 = getByte(word, 3)
		local b1 = getByte(word, 2)
		local b2 = getByte(word, 1)
		local b3 = getByte(word, 0)

		local t = bit.bxor(b3, b2)
		local u = bit.bxor(b1, b0)
		local v = bit.bxor(t, u)
		v = bit.bxor(v, gf.mul(0x08, v))
		w = bit.bxor(v, gf.mul(0x04, bit.bxor(b2, b0)))
		v = bit.bxor(v, gf.mul(0x04, bit.bxor(b3, b1)))

		return putByte(bit.bxor(bit.bxor(b3, v), gf.mul(0x02, bit.bxor(b0, b3))), 0)
			+ putByte(bit.bxor(bit.bxor(b2, w), gf.mul(0x02, t)), 1)
			+ putByte(bit.bxor(bit.bxor(b1, v), gf.mul(0x02, bit.bxor(b0, b3))), 2)
			+ putByte(bit.bxor(bit.bxor(b0, w), gf.mul(0x02, u)), 3)
	end

	local function expandDecryptionKey(key)
		local keySchedule = expandEncryptionKey(key)
		if keySchedule == nil then
			return nil
		end

		keySchedule[KEY_TYPE] = DECRYPTION_KEY

		for i = 4, (keySchedule[ROUNDS] + 1) * 4 - 5 do
			keySchedule[i] = invMixColumnOld(keySchedule[i])
		end

		return keySchedule
	end

	local function addRoundKey(state, key, round)
		for i = 0, 3 do
			state[i + 1] = bit.bxor(state[i + 1], key[round * 4 + i])
		end
	end

	local function doRound(origState, dstState)
		dstState[1] = bit.bxor(
			bit.bxor(
				bit.bxor(table0[getByte(origState[1], 3)], table1[getByte(origState[2], 2)]),
				table2[getByte(origState[3], 1)]
			),
			table3[getByte(origState[4], 0)]
		)

		dstState[2] = bit.bxor(
			bit.bxor(
				bit.bxor(table0[getByte(origState[2], 3)], table1[getByte(origState[3], 2)]),
				table2[getByte(origState[4], 1)]
			),
			table3[getByte(origState[1], 0)]
		)

		dstState[3] = bit.bxor(
			bit.bxor(
				bit.bxor(table0[getByte(origState[3], 3)], table1[getByte(origState[4], 2)]),
				table2[getByte(origState[1], 1)]
			),
			table3[getByte(origState[2], 0)]
		)

		dstState[4] = bit.bxor(
			bit.bxor(
				bit.bxor(table0[getByte(origState[4], 3)], table1[getByte(origState[1], 2)]),
				table2[getByte(origState[2], 1)]
			),
			table3[getByte(origState[3], 0)]
		)
	end

	local function doLastRound(origState, dstState)
		dstState[1] = putByte(SBox[getByte(origState[1], 3)], 3)
			+ putByte(SBox[getByte(origState[2], 2)], 2)
			+ putByte(SBox[getByte(origState[3], 1)], 1)
			+ putByte(SBox[getByte(origState[4], 0)], 0)

		dstState[2] = putByte(SBox[getByte(origState[2], 3)], 3)
			+ putByte(SBox[getByte(origState[3], 2)], 2)
			+ putByte(SBox[getByte(origState[4], 1)], 1)
			+ putByte(SBox[getByte(origState[1], 0)], 0)

		dstState[3] = putByte(SBox[getByte(origState[3], 3)], 3)
			+ putByte(SBox[getByte(origState[4], 2)], 2)
			+ putByte(SBox[getByte(origState[1], 1)], 1)
			+ putByte(SBox[getByte(origState[2], 0)], 0)

		dstState[4] = putByte(SBox[getByte(origState[4], 3)], 3)
			+ putByte(SBox[getByte(origState[1], 2)], 2)
			+ putByte(SBox[getByte(origState[2], 1)], 1)
			+ putByte(SBox[getByte(origState[3], 0)], 0)
	end

	local function doInvRound(origState, dstState)
		dstState[1] = bit.bxor(
			bit.bxor(
				bit.bxor(tableInv0[getByte(origState[1], 3)], tableInv1[getByte(origState[4], 2)]),
				tableInv2[getByte(origState[3], 1)]
			),
			tableInv3[getByte(origState[2], 0)]
		)

		dstState[2] = bit.bxor(
			bit.bxor(
				bit.bxor(tableInv0[getByte(origState[2], 3)], tableInv1[getByte(origState[1], 2)]),
				tableInv2[getByte(origState[4], 1)]
			),
			tableInv3[getByte(origState[3], 0)]
		)

		dstState[3] = bit.bxor(
			bit.bxor(
				bit.bxor(tableInv0[getByte(origState[3], 3)], tableInv1[getByte(origState[2], 2)]),
				tableInv2[getByte(origState[1], 1)]
			),
			tableInv3[getByte(origState[4], 0)]
		)

		dstState[4] = bit.bxor(
			bit.bxor(
				bit.bxor(tableInv0[getByte(origState[4], 3)], tableInv1[getByte(origState[3], 2)]),
				tableInv2[getByte(origState[2], 1)]
			),
			tableInv3[getByte(origState[1], 0)]
		)
	end

	local function doInvLastRound(origState, dstState)
		dstState[1] = putByte(iSBox[getByte(origState[1], 3)], 3)
			+ putByte(iSBox[getByte(origState[4], 2)], 2)
			+ putByte(iSBox[getByte(origState[3], 1)], 1)
			+ putByte(iSBox[getByte(origState[2], 0)], 0)

		dstState[2] = putByte(iSBox[getByte(origState[2], 3)], 3)
			+ putByte(iSBox[getByte(origState[1], 2)], 2)
			+ putByte(iSBox[getByte(origState[4], 1)], 1)
			+ putByte(iSBox[getByte(origState[3], 0)], 0)

		dstState[3] = putByte(iSBox[getByte(origState[3], 3)], 3)
			+ putByte(iSBox[getByte(origState[2], 2)], 2)
			+ putByte(iSBox[getByte(origState[1], 1)], 1)
			+ putByte(iSBox[getByte(origState[4], 0)], 0)

		dstState[4] = putByte(iSBox[getByte(origState[4], 3)], 3)
			+ putByte(iSBox[getByte(origState[3], 2)], 2)
			+ putByte(iSBox[getByte(origState[2], 1)], 1)
			+ putByte(iSBox[getByte(origState[1], 0)], 0)
	end

	local function encrypt(key, input, inputOffset, output, outputOffset)
		inputOffset = inputOffset or 1
		output = output or {}
		outputOffset = outputOffset or 1

		local state = {}
		local tmpState = {}

		if key[KEY_TYPE] ~= ENCRYPTION_KEY then
			warn("No encryption key: " .. tostring(key[KEY_TYPE]) .. ", expected " .. ENCRYPTION_KEY)
			return
		end

		state = util.bytesToInts(input, inputOffset, 4)
		addRoundKey(state, key, 0)

		local round = 1
		while round < key[ROUNDS] - 1 do
			doRound(state, tmpState)
			addRoundKey(tmpState, key, round)
			round = round + 1

			doRound(tmpState, state)
			addRoundKey(state, key, round)
			round = round + 1
		end

		doRound(state, tmpState)
		addRoundKey(tmpState, key, round)
		round = round + 1

		doLastRound(tmpState, state)
		addRoundKey(state, key, round)

		return util.intsToBytes(state, output, outputOffset)
	end

	local function decrypt(key, input, inputOffset, output, outputOffset)
		inputOffset = inputOffset or 1
		output = output or {}
		outputOffset = outputOffset or 1

		local state = {}
		local tmpState = {}

		if key[KEY_TYPE] ~= DECRYPTION_KEY then
			warn("No decryption key: " .. tostring(key[KEY_TYPE]))
			return
		end

		state = util.bytesToInts(input, inputOffset, 4)
		addRoundKey(state, key, key[ROUNDS])

		local round = key[ROUNDS] - 1
		while round > 2 do
			doInvRound(state, tmpState)
			addRoundKey(tmpState, key, round)
			round = round - 1

			doInvRound(tmpState, state)
			addRoundKey(state, key, round)
			round = round - 1
		end

		doInvRound(state, tmpState)
		addRoundKey(tmpState, key, round)
		round = round - 1

		doInvLastRound(tmpState, state)
		addRoundKey(state, key, round)

		return util.intsToBytes(state, output, outputOffset)
	end

	calcSBox()
	calcRoundTables()
	calcInvRoundTables()

	return {
		ROUNDS = ROUNDS,
		KEY_TYPE = KEY_TYPE,
		ENCRYPTION_KEY = ENCRYPTION_KEY,
		DECRYPTION_KEY = DECRYPTION_KEY,

		expandEncryptionKey = expandEncryptionKey,
		expandDecryptionKey = expandDecryptionKey,
		encrypt = encrypt,
		decrypt = decrypt,
	}
end)
local buffer = _W(function(_ENV, ...)
	local function new()
		return {}
	end

	local function addString(stack, s)
		table.insert(stack, s)
	end

	local function toString(stack)
		return table.concat(stack)
	end

	return {
		new = new,
		addString = addString,
		toString = toString,
	}
end)
ciphermode = _W(function(_ENV, ...)
	local public = {}

	local random = math.random
	function public.encryptString(key, data, modeFunction, iv)
		if iv then
			local ivCopy = {}
			for i = 1, 16 do
				ivCopy[i] = iv[i]
			end
			iv = ivCopy
		else
			iv = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
		end

		local keySched = aes.expandEncryptionKey(key)
		local encryptedData = buffer.new()

		for i = 1, #data / 16 do
			local offset = (i - 1) * 16 + 1
			local byteData = { string.byte(data, offset, offset + 15) }

			iv = modeFunction(keySched, byteData, iv)

			buffer.addString(encryptedData, string.char(unpack(byteData)))
		end

		return buffer.toString(encryptedData)
	end

	function public.encryptECB(keySched, byteData, iv)
		aes.encrypt(keySched, byteData, 1, byteData, 1)
	end

	function public.encryptCBC(keySched, byteData, iv)
		util.xorIV(byteData, iv)
		aes.encrypt(keySched, byteData, 1, byteData, 1)
		return byteData
	end

	function public.encryptOFB(keySched, byteData, iv)
		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)
		return iv
	end

	function public.encryptCFB(keySched, byteData, iv)
		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)
		return byteData
	end

	function public.encryptCTR(keySched, byteData, iv)
		local nextIV = {}
		for j = 1, 16 do
			nextIV[j] = iv[j]
		end

		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)

		util.increment(nextIV)

		return nextIV
	end

	function public.decryptString(key, data, modeFunction, iv)
		if iv then
			local ivCopy = {}
			for i = 1, 16 do
				ivCopy[i] = iv[i]
			end
			iv = ivCopy
		else
			iv = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
		end

		local keySched
		if
			modeFunction == public.decryptOFB
			or modeFunction == public.decryptCFB
			or modeFunction == public.decryptCTR
		then
			keySched = aes.expandEncryptionKey(key)
		else
			keySched = aes.expandDecryptionKey(key)
		end

		local decryptedData = buffer.new()

		for i = 1, #data / 16 do
			local offset = (i - 1) * 16 + 1
			local byteData = { string.byte(data, offset, offset + 15) }

			iv = modeFunction(keySched, byteData, iv)

			buffer.addString(decryptedData, string.char(unpack(byteData)))
		end

		return buffer.toString(decryptedData)
	end

	function public.decryptECB(keySched, byteData, iv)
		aes.decrypt(keySched, byteData, 1, byteData, 1)
		return iv
	end

	function public.decryptCBC(keySched, byteData, iv)
		local nextIV = {}
		for j = 1, 16 do
			nextIV[j] = byteData[j]
		end

		aes.decrypt(keySched, byteData, 1, byteData, 1)
		util.xorIV(byteData, iv)

		return nextIV
	end

	function public.decryptOFB(keySched, byteData, iv)
		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)

		return iv
	end

	function public.decryptCFB(keySched, byteData, iv)
		local nextIV = {}
		for j = 1, 16 do
			nextIV[j] = byteData[j]
		end

		aes.encrypt(keySched, iv, 1, iv, 1)
		util.xorIV(byteData, iv)

		return nextIV
	end

	public.decryptCTR = public.encryptCTR

	return public
end)

AES128 = 16
AES192 = 24
AES256 = 32

ECBMODE = 1
CBCMODE = 2
OFBMODE = 3
CFBMODE = 4
CTRMODE = 4

local function pwToKey(password, keyLength, iv)
	local padLength = keyLength
	if keyLength == AES192 then
		padLength = 32
	end

	if padLength > #password then
		local postfix = ""
		for i = 1, padLength - #password do
			postfix = postfix .. string.char(0)
		end
		password = password .. postfix
	else
		password = string.sub(password, 1, padLength)
	end

	local pwBytes = { string.byte(password, 1, #password) }
	password = ciphermode.encryptString(pwBytes, password, ciphermode.encryptCBC, iv)

	password = string.sub(password, 1, keyLength)

	return { string.byte(password, 1, #password) }
end

local script = (function(password, data, keyLength, mode, iv)
	assert(password ~= nil, "Empty password.")
	assert(password ~= nil, "Empty data.")

	local mode = mode or CBCMODE
	local keyLength = keyLength or AES128

	local key = pwToKey(password, keyLength, iv)

	local paddedData = util.padByteString(data)

	if mode == ECBMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptECB, iv)
	elseif mode == CBCMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCBC, iv)
	elseif mode == OFBMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptOFB, iv)
	elseif mode == CFBMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCFB, iv)
	elseif mode == CTRMODE then
		return ciphermode.encryptString(key, paddedData, ciphermode.encryptCTR, iv)
	else
		warn("Unknown mode", 2)
	end
end)(
	"lycoris_encryption_key_101920488A1203819E9248B3920319293CC48127581272138EE82139E",
	readfile("releaseversion1-22.lua"),
	16,
	2
)

writefile("releaseversion1-23.lua", script)