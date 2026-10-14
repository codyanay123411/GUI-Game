--!strict
-- Deterministic interval accounting. Only the server Title service owns a ledger.
export type Account = { value: number, holdings: number, settledAt: number, multiplier: number }
local Accrual = {}
Accrual.__index = Accrual

local function finite(value: number): boolean
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

function Accrual.new(rate: number)
	assert(finite(rate) and rate > 0, "Prestige rate must be finite and positive")
	return setmetatable({ rate = rate, accounts = {} :: { [string]: Account }, cutoff = nil :: number? }, Accrual)
end

function Accrual.AddRuler(self: any, id: string, at: number, holdings: number)
	assert(finite(at), "Invalid Prestige timestamp")
	assert(holdings >= 0 and holdings % 1 == 0, "Invalid personal holding count")
	if self.cutoff or self.accounts[id] then return end
	self.accounts[id] = { value = 0, holdings = holdings, settledAt = at, multiplier = 1 }
end

function Accrual.Get(self: any, id: string, at: number): number
	assert(finite(at), "Invalid Prestige timestamp")
	local account: Account? = self.accounts[id]
	if not account then return 0 end
	local untilAt = if self.cutoff then math.min(at, self.cutoff) else at
	if untilAt > account.settledAt then
		account.value += (untilAt - account.settledAt) * account.holdings * self.rate * (account.multiplier or 1) / 60
		account.settledAt = untilAt
	end
	return account.value
end

function Accrual.SetHoldings(self: any, id: string, holdings: number, at: number)
	assert(finite(holdings) and holdings >= 0 and holdings % 1 == 0, "Invalid personal holding count")
	if self.cutoff then return end
	local account: Account? = self.accounts[id]
	if not account then return end
	assert(at >= account.settledAt, "Prestige transfer predates settled interval")
	self:Get(id, at)
	account.holdings = holdings
end

function Accrual.SetMultiplier(self: any, id: string, factor: number, at: number)
	if self.cutoff or not self.accounts[id] then return end
	assert(finite(factor) and factor >= 0)
	self:Get(id, at);self.accounts[id].multiplier = factor
end

function Accrual.SetValue(self: any, id: string, value: number, at: number)
	assert(finite(value) and value >= 0, "Prestige must be finite and nonnegative")
	if self.cutoff then return end
	assert(self.accounts[id], "Missing Prestige account")
	self:Get(id, at)
	self.accounts[id].value = value
end

function Accrual.Remove(self: any, id: string, at: number)
	if self.cutoff then return end
	self:Get(id, at)
	self.accounts[id] = nil
end

function Accrual.Freeze(self: any, at: number)
	assert(finite(at), "Invalid Prestige cutoff")
	if self.cutoff then return end
	for _, account in self.accounts do
		assert(at >= account.settledAt, "Prestige cutoff predates settlement")
	end
	self.cutoff = at
	for id in self.accounts do self:Get(id, at) end
end

return Accrual
