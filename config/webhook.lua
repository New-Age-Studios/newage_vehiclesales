return {
    -- 1. Global Webhook (Logs all actions to a single channel if set and specific webhooks are blank)
    webhook_all = "PUT YOUR WEBHOOK HERE",

    -- 2. Specific Webhooks (Leave blank to use webhook_all, or to disable entirely)
    webhook_sell = "PUT YOUR WEBHOOK HERE",       -- Triggers when a player places a vehicle for sale
    webhook_buy = "PUT YOUR WEBHOOK HERE",        -- Triggers when a vehicle is bought by a player
    webhook_cancel = "PUT YOUR WEBHOOK HERE",     -- Triggers when a player cancels their listing and returns it to garage
    webhook_delete = "PUT YOUR WEBHOOK HERE",     -- Triggers when a player deletes a record from their sold history
    webhook_sellback = "PUT YOUR WEBHOOK HERE",   -- Triggers when a player sells a vehicle back directly to the concessionaire
}
