--- STEAMODDED HEADER
--- MOD_NAME: Rule Breaker
--- MOD_ID: RuleBreaker
--- MOD_AUTHOR: [RakibRyan]
--- MOD_DESCRIPTION: Allows playing & discarding +1 card per hand.
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
-- Joker Definition
----------------------------------------------
SMODS.Joker {
    key = "rule_breaker",
    unlocked = true,
    discovered = true, 
    loc_txt = {
        name = "Rule Breaker",
        text = {
            "Allows playing & discarding {C:attention}+#1#{} additional",
            "card per hand."
        }
    },
    
    config = { extra = { extra_cards = 1 } },
    rarity = 1,
    cost = 6,
    atlas = "rule_breaker_atlas",
    pos = { x = 0, y = 0 },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.extra_cards } }
    end,

    -- TRIGGER: When Joker is added to Joker slots
    add_to_deck = function(self, card, from_debuff)
        G.hand.config.highlighted_limit = G.hand.config.highlighted_limit + card.ability.extra.extra_cards
    end,

    -- TRIGGER: When Joker is sold, destroyed, or debuffed
    remove_from_deck = function(self, card, from_debuff)
        G.hand.config.highlighted_limit = G.hand.config.highlighted_limit - card.ability.extra.extra_cards
    end
}

----------------------------------------------
-- Extra Card Limit Support (Non-Destructive Hook)
----------------------------------------------
local old_can_play = G.FUNCS.can_play
G.FUNCS.can_play = function(e)
    old_can_play(e)

    local limit = G.hand.config.highlighted_limit or 5
    local highlighted = #G.hand.highlighted

    if highlighted > 5 and highlighted <= limit then
        e.config.colour = G.C.BLUE
        e.config.button = 'play_cards_from_highlighted'
    end
end

local old_can_discard = G.FUNCS.can_discard
G.FUNCS.can_discard = function(e)
    old_can_discard(e)

    local limit = G.hand.config.highlighted_limit or 5
    local highlighted = #G.hand.highlighted

    if highlighted > 5 and highlighted <= limit and G.GAME.current_round.discards_left > 0 then
        e.config.colour = G.C.RED
        e.config.button = 'discard_cards_from_highlighted'
    end
end

