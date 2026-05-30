--- STEAMODDED HEADER
--- MOD_NAME: Rule Breaker
--- MOD_ID: RuleBreaker
--- MOD_AUTHOR: [YourName]
--- MOD_DESCRIPTION: Allows playing +1 card per hand. Gives +4 Mult and a random Tarot card every hand played.
--- PRIORITY: 0
--- VERSION: 1.0.0

----------------------------------------------
-- Atlas
----------------------------------------------
SMODS.Atlas {
    key = "rule_breaker_atlas",
    path = "rule_breaker.png",
    px = 71,
    py = 95,
}








----------------------------------------------
-- Extra Card Limit Support (Non-Destructive Hook)
----------------------------------------------

-- Hook for Play Button
local old_can_play = G.FUNCS.can_play
G.FUNCS.can_play = function(e)
    -- 1. Execute the original engine logic first (preserves debuffs, tutorials, and other mods)
    old_can_play(e)

    -- 2. Define our custom limits
    local limit = G.hand.config.highlighted_limit or 5
    local highlighted = #G.hand.highlighted

    -- 3. Intervene ONLY if the selected cards exceed the vanilla limit but are within our custom limit
    if highlighted > 5 and highlighted <= limit then
        e.config.colour = G.C.BLUE
        e.config.button = 'play_cards_from_highlighted'
    end
end

-- Hook for Discard Button
local old_can_discard = G.FUNCS.can_discard
G.FUNCS.can_discard = function(e)
    -- 1. Execute original engine logic first
    old_can_discard(e)

    -- 2. Define our custom limits
    local limit = G.hand.config.highlighted_limit or 5
    local highlighted = #G.hand.highlighted

    -- 3. Intervene ONLY if conditions are met AND the player has discards remaining
    if highlighted > 5 and highlighted <= limit and G.GAME.current_round.discards_left > 0 then
        e.config.colour = G.C.RED
        e.config.button = 'discard_cards_from_highlighted'
    end
end










----------------------------------------------
-- Joker Definition
----------------------------------------------
SMODS.Joker {
    key = "rule_breaker",
    unlocked = true,
    discovered = true, 

    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt = {
        name = "Rule Breaker",
        text = {
            "Allows playing {C:attention}+#2#{} additional",
            "card per hand.",
            "{C:mult}+#1#{} Mult",
            "Gives a random {C:tarot}Tarot{}",
            "card after each hand played",
        }
    },
    -- Added extra_cards to the config
    config = { extra = { mult = 4, extra_cards = 1 } },
    rarity = 1,
    cost = 2,
    atlas = "rule_breaker_atlas",
    pos = { x = 0, y = 0 },

    loc_vars = function(self, info_queue, card)
        -- Added the extra_cards variable so it displays on the card
        return { vars = { card.ability.extra.mult, card.ability.extra.extra_cards } }
    end,

    -- TRIGGER: When Joker is added to your Joker slots
    add_to_deck = function(self, card, from_debuff)
        G.hand.config.highlighted_limit = G.hand.config.highlighted_limit + card.ability.extra.extra_cards
    end,

    -- TRIGGER: When Joker is sold, destroyed, or debuffed
    remove_from_deck = function(self, card, from_debuff)
        G.hand.config.highlighted_limit = G.hand.config.highlighted_limit - card.ability.extra.extra_cards
    end,

    -- Original calculate logic for Mult and Tarot cards
    calculate = function(self, card, context)
        -- +4 Mult during scoring
        if context.joker_main then
            return {
                mult = card.ability.extra.mult,
                message = localize { type = "variable", key = "a_mult", vars = { card.ability.extra.mult } },
                colour = G.C.MULT,
            }
        end

        -- Give a Tarot card after each hand played
        if context.after and context.main_eval then
            local tarot_keys = {}
            for k, v in pairs(G.P_CENTERS) do
                if v.set == "Tarot" then
                    tarot_keys[#tarot_keys + 1] = k
                end
            end

            if #tarot_keys > 0 then
                local chosen = tarot_keys[math.random(#tarot_keys)]
                G.E_MANAGER:add_event(Event({
                    func = function()
                        local new_card = create_card("Tarot", G.consumeables, nil, nil, nil, nil, chosen, "rule_breaker")
                        new_card:add_to_deck()
                        G.consumeables:emplace(new_card)
                        card:juice_up(0.5, 0.5)
                        play_sound("card1")
                        return true
                    end
                }))
                return {
                    message = "Tarot!",
                    colour = G.C.PURPLE,
                }
            end
        end
    end,
}

