return {
    -- 1. Global Webhook (Logs all actions to a single channel if set and specific webhooks are blank)
    webhook_all = "https://discord.com/api/webhooks/1483613558154461195/L4SgUmnkWqiU1RInacvkSDqD3dK0PAiMeuBjBYSvodI_XCiCLFfpk0cQp3e0MJAlEiJ0",

    -- 2. Specific Webhooks (Leave blank to use webhook_all, or to disable entirely)
    webhook_sell = "",       -- Triggers when a player places a vehicle for sale
    webhook_buy = "",        -- Triggers when a vehicle is bought by a player
    webhook_cancel = "",     -- Triggers when a player cancels their listing and returns it to garage
    webhook_delete = "",     -- Triggers when a player deletes a record from their sold history
    webhook_sellback = "",   -- Triggers when a player sells a vehicle back directly to the concessionaire
}
