-- Dialogue: all character voices, sequenced arcs, wharf lines
-- Ports WharfVoices.swift (776 lines)

local Dialogue = {}

-- Hub characters
Dialogue.Characters = { "higgs", "maren", "cully", "sable" }

Dialogue.CharacterDisplayName = {
    higgs = "Higgs", maren = "Maren", cully = "Cully", sable = "Sable",
}

Dialogue.CharacterRole = {
    higgs = "The Bosun",
    maren = "Ship's Accountant",
    cully = "Chronic Gambler",
    sable = "The Old Rigger",
}

Dialogue.CharacterRequiredNode = {
    higgs = nil,
    maren = "narrativeMaren",
    cully = "narrativeCully",
    sable = "narrativeSable",
}

-------------------------------------------------------------------------------
-- Higgs
-------------------------------------------------------------------------------

local Higgs = {
    won = {
        "Back. I'll note the crossing.",
        "Afloat. The ledger shows a completion. That's what I'll file.",
        "Made port. I'll amend the record.",
        "Afloat again. The endorsement is still outstanding — no change there.",
        "I'll add it to the list of ships that came back. It's a shorter list than you'd think.",
        "Good crossing. I've updated the log.",
    },
    founderedWatch1 = {
        "Watch one. Hard to say what happened out there.",
        "Short crossing. I've updated the records.",
        "Watch one is no guarantee. I keep telling people that.",
        "First watch. I'll amend the log. It happens more than anyone admits.",
        "The sea doesn't owe you a full voyage. Sometimes it takes that literally.",
    },
    founderedMid = {
        "Came apart in the middle. Most do.",
        "Made it past the early stretch. That's not nothing. It's also not port.",
        "I've seen better starts end worse. That's not comfort — just observation.",
        "Mid-voyage is where the voyages that were going to founder mostly do.",
        "You had something going. The ledger doesn't record what might have been.",
        "I'll file it as a standard foundering. The sea doesn't give reasons.",
    },
    founderedLate = {
        "Close doesn't go in the log. But I remember it.",
        "Late foundering. Those are the ones that stick.",
        "Made it that far. That's the part that matters and the part that doesn't, simultaneously.",
        "I've seen worse get worse. I've seen better not make it either.",
        "The last watches are where the voyages that nearly make it end.",
        "I'll write it up. It'll read the same as the rest. It wasn't the same.",
    },
    firstRun = {
        "The pamphlet's a bit out of date but the general shape of things is right.",
        "Forms are on the counter if you want to get ahead of things.",
        "The Mayor's Income is ready when you are.",
    },
    returningAfterFoundering = {
        "Rough one. The forms are on the counter if you want to get ahead of things.",
        "Current was bad past the third marker. I've filed the usual report.",
        "Take your time. There's no queue.",
        "I'll update the ledger.",
    },
    returningAfterPort = {
        "Back again. I'll note it.",
        "Good crossing. The endorsement is still processing — no change there.",
        "The Reaches were clear, I take it.",
    },
    provisions = {
        "Flotsam's the only currency that outlasts a voyage.",
        "Spend it or it just sits here. Either way I'm keeping the shelves stocked.",
        "Salvage is what's left after everything else is gone. Use it wisely.",
        "Most sailors spend their flotsam on the first thing they see. Some don't.",
        "This stuff doesn't spoil. Neither does regret.",
        "Come back enough times, you start to know what you actually need.",
        "Flotsam is patient. Spend it when you're ready.",
        "Some provisions pay out slow. Some you'll feel on the first hand.",
        "You don't have to spend it all now. You do have to spend it eventually.",
        "Nothing I sell here will win a voyage. But the right thing might not lose you one.",
        "Every piece of flotsam was once part of something that didn't make port.",
        "I keep it stocked because people keep coming back. Draw your own conclusions.",
        "Provisions are what separate the voyagers from the gamblers.",
        "Modifiers win hands. Provisions win voyages.",
        "The upgrades aren't there to make it easy. They're there to make it possible.",
        "Seen a man spend three voyages of flotsam on the first thing in the list. Won his fourth run.",
        "A good provision runs quiet in the background. You won't notice it until you need it.",
        "There's no wrong choice here. There are slow ones.",
        "I've been asked what the best pick is. I've never answered.",
        "Flotsam has a way of adding up. So does everything it buys.",
    },
    general = {
        "Still nothing back on the endorsement. These things move at their own pace.",
        "I resubmitted with the new reference number. Should make no difference.",
        "You don't need me to tell you how it went. I can tell from the flotsam.",
        "Nobody's asked about the Mayor's Income again, if you were wondering.",
        "I put fresh ink in the stamp. Not sure what for.",
        "Weather looks the same as it did.",
        "Someone left a coat last week. Might be yours. I couldn't say.",
        "I don't keep a count. I just keep the records.",
        "You're getting consistent. That's something.",
        "Everything worth having washed up here sooner or later.",
        "The tide doesn't care what you planned.",
        "Seen a lot of ships leave this wharf. Fewer come back.",
        "Wind's picking up. Make it quick.",
        "Three watches. That's all anyone gets.",
        "You float or you don't. Nothing in between.",
        "Water remembers every wreck.",
        "I don't give credit. Ask the sea how that goes.",
        "Storm's coming. Buy something useful.",
        "Most things that sink were perfectly good ships.",
        "The sea has no opinion of you. That's almost comforting.",
        "I stock what works. What works changes.",
        "Gear doesn't win voyages. Knowing when to use it does.",
        "Everything here's been on a ship before. Some of those ships made port.",
        "Some of this belonged to someone who didn't need it anymore.",
        "Don't read too much into the selection.",
        "Buy something or don't. I've got rope to coil.",
        "I'm not here to talk you into anything.",
        "The good stuff goes fast. This is what's left.",
        "I've been on this wharf longer than the planks.",
        "Chips are just water. They flow toward who deserves them least.",
        "A big stack doesn't keep you afloat. A smart bet might.",
        "Seen men with nothing win. Seen men with plenty founder in flat calm.",
        "Double down if you must. I've seen worse decisions.",
        "The house always has the wind behind it. You're sailing into it.",
    },
    byWatch = {
        [1] = {
            "First watch is the easy one. Or so people think.",
            "You look new. The sea will fix that.",
            "Don't spend it all in watch one. Lesson number one.",
            "Everyone's optimistic in watch one.",
            "A good first watch doesn't mean a good voyage. A bad one might.",
            "Watch one is when you still have choices.",
            "You haven't made your worst mistake yet. That's coming.",
            "Three watches ahead. Make this one matter.",
            "Had a man start with nothing and finish a winner. Started just like you.",
            "Buy something that'll hold up. You've got distance to cover.",
        },
        [2] = {
            "Halfway through and still standing. That's more than most.",
            "Second watch is where the voyage gets real.",
            "You've got your stack. Question is what you do with it from here.",
            "Ships don't sink in calm. They sink when the crew gets complacent.",
            "Watch two is when you see what's actually working.",
            "Don't let watch two lull you. Watch three has no mercy.",
            "Still here. Some would call that a win already.",
            "Whatever you bought last time — hope it's earned its keep.",
            "Halfway through and still breathing. Good sign.",
            "Had a man start watch two up five hundred. Left watch three with nothing.",
        },
        [3] = {
            "Third watch. Last chance to get it right.",
            "You've made it this far. That means nothing and everything.",
            "It ends here one way or another.",
            "Last watch. What do you actually need?",
            "Some men pray in the third watch. Never seen it help.",
            "Nothing left to save for. Spend it.",
            "Third watch is where it gets honest.",
            "You want encouragement? You're still alive. That's it.",
            "Had a man stand here twenty minutes once. Didn't buy a thing. Drowned in watch three.",
            "I've seen worse starts finish well. I've seen worse finishes too.",
        },
    },
}

function Higgs.hubLine(actsCompleted, outcome)
    if outcome == "won" then return Higgs.won[math.random(#Higgs.won)] end
    if outcome == "foundered" then
        if actsCompleted == 0 then return Higgs.founderedWatch1[math.random(#Higgs.founderedWatch1)] end
        if actsCompleted <= 2 then return Higgs.founderedMid[math.random(#Higgs.founderedMid)] end
        return Higgs.founderedLate[math.random(#Higgs.founderedLate)] end
    return Higgs.general[math.random(#Higgs.general)]
end

function Higgs.followUp(actsCompleted, outcome)
    if outcome == "won" then
        local lines = {
            "The log's been updated. Don't read too much into it.",
            "I won't say I expected it. But I noted it.",
            "Makes the record look better. Small thing.",
            "I'll add your name to the short list.",
        }
        return lines[math.random(#lines)]
    end
    if outcome == "foundered" then
        if actsCompleted == 0 then
            local lines = {
                "Happens more than you'd think. Doesn't make it easier.",
                "I've seen worse starts. Most of them.",
                "The ledger doesn't judge. Neither do I.",
            }
            return lines[math.random(#lines)]
        end
        if actsCompleted <= 2 then
            local lines = {
                "Middle's where most of them go. Still not a rule.",
                "You had it for a while there.",
                "I'll note the watches. That part was real.",
            }
            return lines[math.random(#lines)]
        end
        local lines = {
            "Close is a different kind of hard.",
            "I'll note the watches. It's something.",
            "That far in. The record will show it.",
        }
        return lines[math.random(#lines)]
    end
    return Higgs.general[math.random(#Higgs.general)]
end

-------------------------------------------------------------------------------
-- Maren
-------------------------------------------------------------------------------

local Maren = {
    won = {
        "Statistically improbable. Congratulations. The math was against you.",
        "You made port. I'll admit I've run those odds. They're not good.",
        "Win rate adjusted. You're above median for completed voyages. That's a small group.",
        "A completed crossing. Expected value finally converged in your favour.",
        "I've tracked four hundred voyages. Wins are approximately one in eight. You managed it.",
    },
    founderedEarly = {
        "Watch one is statistically your most recoverable watch. You did not recover.",
        "Early foundering. The EV on watch one play was poor. That compounds.",
        "You had the lowest-variance window and used it badly. We can work on that.",
        "Watch one foundering suggests a fundamental sizing problem. Or variance. Probably both.",
    },
    founderedMid = {
        "Mid-voyage collapse. Your bet sizing diverged from optimal around watch two.",
        "The EV was recoverable. You didn't recover it. That's a decision problem.",
        "I tracked your stack. It was salvageable through watch two. Then it wasn't.",
        "Mid-voyage is where discipline separates the survivors. The data on this is clear.",
    },
    founderedLate = {
        "Watch four or five. You were within expected variance of a win. That's the hardest kind.",
        "Late foundering is a sizing or modifier problem. You were close enough that small changes matter.",
        "The EV on your final watches was positive. Variance ate it. That happens.",
        "That far in and still foundering means your late-game decisions need work. Or you got unlucky. Possibly both.",
    },
    general = {
        "The house edge is a tax on intuition.",
        "Seventeen is the worst hand in the game. You'll see it more than you want.",
        "Insurance is a bad bet. I don't care what it feels like.",
        "The dealer's up card tells you everything you should need.",
        "Split aces. Always. That's not opinion, it's arithmetic.",
        "A modifier is only worth its cost in expected value. Some of these are.",
        "Variance isn't luck. You'll understand the difference after enough hands.",
        "The optimal play is the same whether you're up or down. That's the point.",
        "Every decision compounds. Small edges become large ones over a run.",
    },
    byWatch = {
        [1] = {
            "House edge is 0.5% with optimal play. You're probably not playing optimally.",
            "First watch is your lowest-variance period. Establish a baseline.",
            "Expected value applies to every decision. Even the ones that feel like instinct.",
            "Don't deviate from strategy in watch one. You don't have enough data yet.",
            "The deck has no memory. You do. That's the only edge you have.",
            "Start conservatively. Recklessness in watch one destroys watch three.",
            "I've tracked optimal play across four hundred voyages. Watch one bets should be flat.",
        },
        [2] = {
            "Check your stack against your expected burn rate. If you're ahead, you're getting lucky.",
            "Mid-voyage is where variance looks like skill. It's usually variance.",
            "The shoe has cycled. Whatever you thought you knew about the count, reset it.",
            "You should be running about a 47% win rate on player hands. Above that is temporary.",
            "Second watch is statistically identical to first watch. Your feelings about it are not data.",
            "If you're behind expected value by watch two, you've been playing suboptimally or getting unlucky. Probably both.",
        },
        [3] = {
            "Watch three is when underfunded players make desperate bets. Don't.",
            "Final watch. Calculate what you need per hand. Bet accordingly. No heroics.",
            "The optimal play in watch three is the same as watch one. Discipline doesn't negotiate.",
            "Chasing losses in watch three is how you turn a recoverable deficit into a fust.",
            "If you need more than a 20% gain per hand to win, your bet sizing has been wrong all run.",
            "I've seen the math on third-watch comebacks. They happen. They're not a strategy.",
        },
    },
}

function Maren.hubLine(actsCompleted, outcome)
    if outcome == "won" then return Maren.won[math.random(#Maren.won)] end
    if outcome == "foundered" then
        if actsCompleted == 0 then return Maren.founderedEarly[math.random(#Maren.founderedEarly)] end
        if actsCompleted <= 2 then return Maren.founderedMid[math.random(#Maren.founderedMid)] end
        return Maren.founderedLate[math.random(#Maren.founderedLate)] end
    return Maren.general[math.random(#Maren.general)]
end

function Maren.followUp(actsCompleted, outcome)
    if outcome == "won" then
        local lines = {
            "Don't mistake good variance for good strategy.",
            "Sample size is still too small for conclusions.",
            "You won. The math was against you. I've noted both facts.",
        }
        return lines[math.random(#lines)]
    end
    if outcome == "foundered" then
        if actsCompleted == 0 then
            local lines = {
                "Watch one losses are recoverable in aggregate. This one wasn't.",
                "The expected loss in watch one is bounded. You found the bound.",
            }
            return lines[math.random(#lines)]
        end
        if actsCompleted <= 2 then
            local lines = {
                "The error was recoverable through watch two. Then it wasn't.",
                "I've run those numbers. You should play differently.",
            }
            return lines[math.random(#lines)]
        end
        local lines = {
            "That close to the threshold and still under. The margin was small.",
            "Late foundering is a sizing problem, not a luck problem. Usually.",
        }
        return lines[math.random(#lines)]
    end
    return Maren.general[math.random(#Maren.general)]
end

-------------------------------------------------------------------------------
-- Cully
-------------------------------------------------------------------------------

local Cully = {
    won = {
        "You actually did it. I've been watching people try that for years. You did it.",
        "I had a feeling about this one. I say that every time. This time I meant it.",
        "That's a winning voyage. I'm going to remember this one. I remember all the wins.",
        "Good run. Really good run. I'm going to think about what you did differently. For research.",
        "You made it. I've made it twice. Both times I cried a little. No judgment.",
    },
    founderedEarly = {
        "Watch one. Brutal. I've done that. More than once. More than twice.",
        "That's rough. Watch one's supposed to be the easy part. It mostly is. Mostly.",
        "I once foundered in watch one with a nineteen. Still don't know how. You'll be fine.",
        "Early exits hurt different. You had all that hope still in you.",
    },
    founderedMid = {
        "Mid-voyage. That's where I live. Metaphorically speaking.",
        "Made it past watch one and then lost it. Story of my gambling career, honestly.",
        "I had a run like that last month. And the month before. You're in good company.",
        "Watch two or three — that's the graveyard of almost-good-runs. I've got a plot there.",
    },
    founderedLate = {
        "That close. That is a painful kind of close. I know that close.",
        "Watch four or five and then nothing. I have nightmares with that exact shape.",
        "You almost had it. I mean that genuinely. You were right there.",
        "Late foundering is the cruelest one. I've experienced it eleven times. Eleven.",
    },
    general = {
        "I had a seventeen once. Still don't know why I hit.",
        "The loan's not the worst thing. I've taken it nine times.",
        "I've won with every modifier. I've also lost with every modifier.",
        "Your instincts are fine. Just check them against something first.",
        "You know what they say — the house always wins. I've beaten the house. Twice.",
        "I've been on this wharf a long time. Don't read too much into that.",
        "Split when you can. That's my rule. I've also broken that rule. Multiple times.",
        "I track patterns. The patterns don't track back. But I keep going.",
        "Best advice I ever got: stand on sixteen when the dealer shows six. Worst advice: everything else I've been told.",
    },
    byWatch = {
        [1] = {
            "I had a feeling about this voyage. I always have a feeling. Means nothing.",
            "Watch one's when the good runs start. Or the bad ones. Hard to tell from here.",
            "I once started a run by splitting tens. Won. Still wasn't the right call.",
            "You've got that look. Either you're going to clean up or you're not. Same look either way.",
            "Buy the expensive one. That's my advice. I'm also down seven hundred lifetime.",
            "First watch always feels like the one. They all feel like the one.",
            "I used to have a system for watch one. Twelve systems, actually. None of them worked.",
        },
        [2] = {
            "Halfway through and still feeling it. Or I've lost the feeling. Honestly hard to say.",
            "Second watch always feels different. It isn't, but it feels like it is.",
            "I hit seventeen last week. Dealer had eighteen. That's not a lesson, that's just a fact.",
            "You're doing better than me. That's true every time I say it.",
            "Mid-voyage is when my systems usually fall apart. I'm working on that.",
            "I once had four consecutive pushes in watch two and thought I'd cracked something. I hadn't.",
        },
        [3] = {
            "Third watch. This is the one. I can feel it. I always feel it.",
            "I've made it to watch three maybe forty times. Won it twice. Those were good days.",
            "Don't go fust. That's all I've got. Don't go fust.",
            "Third watch, everything feels possible. About half of it is.",
            "Seen a man double down his entire stack in watch three. Won. Never saw him again.",
            "My record in third watch is not something I advertise. You'll do better.",
            "I once stood on twelve in watch three with a dealer showing five. I'm not saying it worked. I'm not saying it didn't.",
        },
    },
}

function Cully.hubLine(actsCompleted, outcome)
    if outcome == "won" then return Cully.won[math.random(#Cully.won)] end
    if outcome == "foundered" then
        if actsCompleted == 0 then return Cully.founderedEarly[math.random(#Cully.founderedEarly)] end
        if actsCompleted <= 2 then return Cully.founderedMid[math.random(#Cully.founderedMid)] end
        return Cully.founderedLate[math.random(#Cully.founderedLate)] end
    return Cully.general[math.random(#Cully.general)]
end

function Cully.followUp(actsCompleted, outcome)
    if outcome == "won" then
        local lines = {
            "I told someone about you. They didn't believe me.",
            "Right, so I had a system that would've predicted that. Didn't use it. Beside the point.",
            "Good run. Really good run. I'm going to think about what you did differently.",
        }
        return lines[math.random(#lines)]
    end
    if outcome == "foundered" then
        if actsCompleted == 0 then
            local lines = {
                "It was still a run. Counts in the log.",
                "I've done worse. I really have. Watch one's brutal.",
            }
            return lines[math.random(#lines)]
        end
        if actsCompleted <= 2 then
            local lines = {
                "Middle's the graveyard for almost-good-runs. I know this personally.",
                "You had something going there. It showed.",
            }
            return lines[math.random(#lines)]
        end
        local lines = {
            "That close. I know that close. It's the worst kind.",
            "You were right there. Right there.",
        }
        return lines[math.random(#lines)]
    end
    return Cully.general[math.random(#Cully.general)]
end

-------------------------------------------------------------------------------
-- Sable
-------------------------------------------------------------------------------

local Sable = {
    won = {
        "Made port. I've crewed for captains who spent a career trying for that. You've done it.",
        "A completed voyage. The sea gave you a crossing and you held it. That's rarer than it sounds.",
        "I've watched a lot of ships leave this wharf. Fewer come back. You came back.",
        "Good crossing. The kind you remember. The sea remembers them too, in its way.",
        "Afloat. I'll add it to the list in my head. It's a short list. You're on it now.",
    },
    founderedEarly = {
        "First watch is the longest and the shortest, depending on how it goes.",
        "Early crossings that end early still teach something. The sea always charges for the lesson.",
        "Watch one foundering. I've seen it. The ship doesn't know it's your first watch. The sea doesn't either.",
        "Short voyage. The sea's been taking short ones since before either of us was here.",
    },
    founderedMid = {
        "Mid-crossing is where most ships actually founder. The data and the experience agree on that.",
        "The middle of a voyage is the hardest place to read. You're too far from either end.",
        "I've rigged ships that made it past the early stretch and still went down in the middle. It happens.",
        "Two or three watches in. You had the ship moving. Something changed.",
    },
    founderedLate = {
        "Late foundering. The sea saved its worst for when you were closest.",
        "You made it that far. I've watched ships founder in sight of port. It's a hard thing.",
        "The last watches are the ones that sort out who was actually going to make it.",
        "Close crossings that don't finish are the ones that stay with you. This one will stay with you.",
        "I've seen the late watches take sailors who had no business losing. You were close.",
    },
    general = {
        "The sea runs on patterns. So does this game. Neither cares if you notice.",
        "Some captains take the loan. Some don't. Both kinds have drowned.",
        "A good modifier is like good rigging. You don't notice it until you need it.",
        "A run doesn't mean a thing until it's over. Even then, barely.",
        "I've crewed for a lot of captains. The ones who last are the ones who adjust.",
        "This game rewards the same thing the sea does. Patience, mostly.",
        "I've seen men with nothing make port. I've seen men with everything founder. The ship doesn't care.",
        "What you buy here matters less than how you use it. That's true of most things.",
    },
    byWatch = {
        [1] = {
            "Every voyage starts the same. The endings vary.",
            "New run, clean hands. Make something of it.",
            "The ship doesn't know your record. Treat it like your first crossing.",
            "I've seen a hundred captains stand where you're standing. Most of them were fine.",
            "First watch is when you still believe it's mostly about skill.",
            "Set your course in watch one and hold it. Changing course mid-run costs more than most people think.",
            "I once rigged a ship that made port on its first crossing and never came back. Sometimes once is enough.",
        },
        [2] = {
            "You're in the middle now. It's the hardest place to read from.",
            "A ship in mid-crossing is committed. So are you.",
            "Second watch, the crew starts showing who they really are. Same with captains.",
            "I've rigged sails on every kind of ship. They all move the same when the wind drops.",
            "Halfway means you've learned something about this particular run. Whether you've understood it is different.",
            "Mid-crossing is when experienced captains are most dangerous. They've stopped being careful.",
        },
        [3] = {
            "Last watch. I've seen men run it with nothing and come home. I've seen the other kind too.",
            "The sea doesn't decide until the end. Neither does this.",
            "Third watch is when everything becomes clear. Sometimes too late, sometimes just right.",
            "I once crewed for a captain who said third watch was the only watch that counted. He was wrong about a lot, but right about that.",
            "You want the secret? There isn't one. There's just the work.",
            "Last watch is the same as the first one, except you know how much it costs now.",
            "I've watched a lot of third watches from the rigging. The ones who stay calm usually make it. Usually.",
        },
    },
}

function Sable.hubLine(actsCompleted, outcome)
    if outcome == "won" then return Sable.won[math.random(#Sable.won)] end
    if outcome == "foundered" then
        if actsCompleted == 0 then return Sable.founderedEarly[math.random(#Sable.founderedEarly)] end
        if actsCompleted <= 2 then return Sable.founderedMid[math.random(#Sable.founderedMid)] end
        return Sable.founderedLate[math.random(#Sable.founderedLate)] end
    return Sable.general[math.random(#Sable.general)]
end

function Sable.followUp(actsCompleted, outcome)
    if outcome == "won" then
        local lines = {
            "The sea let you through. Worth noting.",
            "A completed crossing stays with a ship. This one will.",
            "I've watched a lot of ships leave this wharf. Fewer come back. You came back.",
        }
        return lines[math.random(#lines)]
    end
    if outcome == "foundered" then
        if actsCompleted == 0 then
            local lines = {
                "The sea doesn't owe anyone a full voyage. It still costs something.",
                "Short crossings teach the same things as long ones. Just faster.",
            }
            return lines[math.random(#lines)]
        end
        if actsCompleted <= 2 then
            local lines = {
                "The middle of a crossing is the hardest place to read. That's not an excuse. Just a fact.",
                "You were committed. That's a different thing from being right.",
            }
            return lines[math.random(#lines)]
        end
        local lines = {
            "Close crossings that don't finish are the ones that stay with you.",
            "I've watched ships founder in sight of port. It's a hard thing to carry.",
        }
        return lines[math.random(#lines)]
    end
    return Sable.general[math.random(#Sable.general)]
end

-------------------------------------------------------------------------------
-- Character registry
-------------------------------------------------------------------------------

local Characters = {
    higgs = Higgs,
    maren = Maren,
    cully = Cully,
    sable = Sable,
}

-- Sequent narrative arcs (one line per run, in order)
Dialogue.Arcs = {
    higgs = {
        "The endorsement came back rejected. Wrong reference number. I've resubmitted.",
        "There's a ship in berth three. The Mayor's Income. She's been there three years. I don't discuss the particulars.",
        "Someone came asking about the Reaches last week. I gave them the standard information. There isn't much.",
        "The endorsement requires a counter-signature from the harbour authority. The harbour authority dissolved in the reorganisation. I'm still filing.",
        "I pulled the Mayor's Income file this morning. There's a notation on the final entry. I didn't recognise the format.",
        "You've been back enough times that I've started expecting you. I don't usually note that. I'm noting it.",
        "That notation on the Mayor's Income file — I found it on three other records. None of those ships came back from the Reaches.",
        "I don't know what's out there. I keep the records. That's the extent of what I know how to do.",
    },
    maren = {
        "I've been running numbers on your crossing decisions. Your variance is high. That's a choice or a problem. I can't tell which yet.",
        "I was accountant on the Calloway Cross. Two successful crossings. The third time out, I wasn't on the manifest. Equipment problem. Minor.",
        "The Calloway Cross's final log shows optimal play through watch four. Watch five has no entries. Ships don't usually stop filing mid-crossing.",
        "Your decision quality has improved by measurable margins since I started tracking. I don't know what to do with that information.",
        "I asked Higgs about the Mayor's Income. He said it was administrative. He says that about a lot of things that aren't.",
        "I keep a second ledger. My own. Ships departed against ships returned. The shortfall is larger than the official records account for. I haven't decided what to do with that.",
    },
    cully = {
        "I've been on this wharf since — actually that's more detail than I meant to share. A while. It's been a while.",
        "I had a system. The Drift System. Lost fifty chips over four runs before I admitted the problem was the system. Rebuilt it. Lost forty more.",
        "I've taken the loan more times than I'd like to count. More than I will count, specifically. The point is it always felt right at the time.",
        "I've seen two people make port in all the time I've been here. Two. They both had this look afterward. I've been trying to replicate the look.",
        "I've never made port. Forty-one runs. I want to be clear I'm not embarrassed. The number is what it is.",
        "I come back because it's always almost. Last hand, almost. Watch three, almost. Almost is enough to live on if you're careful. Don't take that as advice.",
    },
    sable = {
        "I rigged the sails on a ship called the Maud. Forty years ago. She was a fine ship.",
        "The Maud made port six times. I crewed four of those crossings. The seventh, I was ashore — a rigging problem, nothing significant.",
        "The Maud didn't come back from the seventh crossing. I've had forty years to think about what the difference was.",
        "I mentioned the Maud to Higgs once. He pulled a file. Showed me a notation on the final entry. I recognised the format. I didn't tell him that.",
        "Everyone here is waiting for something. The ones who make port know what it is. The ones who don't, mostly don't. I've been trying to figure out which one I am.",
        "The Maud's last log entry was coordinates. I looked them up. There's nothing there. Nothing I can find.",
    },
}

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function Dialogue.sequencedLine(character, index)
    local arc = Dialogue.Arcs[character]
    if not arc or index < 1 or index > #arc then return nil end
    return arc[index]
end

function Dialogue.hubLine(character, actsCompleted, outcome)
    local c = Characters[character]
    if not c then return "" end
    return c.hubLine(actsCompleted, outcome)
end

function Dialogue.hubFollowUp(character, actsCompleted, outcome)
    local c = Characters[character]
    if not c then return "" end
    return c.followUp(actsCompleted, outcome)
end

function Dialogue.randomWharfSpeaker(watch, unlockedNodes)
    local pool = { { name = "Higgs", general = Higgs.general, watchLines = Higgs.byWatch } }
    if unlockedNodes["narrativeMaren"] then
        table.insert(pool, { name = "Maren", general = Maren.general, watchLines = Maren.byWatch })
    end
    if unlockedNodes["narrativeCully"] then
        table.insert(pool, { name = "Cully", general = Cully.general, watchLines = Cully.byWatch })
    end
    if unlockedNodes["narrativeSable"] then
        table.insert(pool, { name = "Sable", general = Sable.general, watchLines = Sable.byWatch })
    end

    local speaker = pool[math.random(#pool)]
    local specific = speaker.watchLines[watch] or {}
    local line
    if #specific > 0 and math.random(100) < 65 then
        line = specific[math.random(#specific)]
    else
        line = speaker.general[math.random(#speaker.general)]
    end
    return { name = speaker.name, line = line }
end

function Dialogue.randomProvisionsLine()
    return Higgs.provisions[math.random(#Higgs.provisions)]
end

function Dialogue.runStartLine(previousOutcome, runCount)
    if previousOutcome == "inProgress" then
        return Higgs.firstRun[math.random(#Higgs.firstRun)]
    elseif previousOutcome == "won" then
        return Higgs.returningAfterPort[math.random(#Higgs.returningAfterPort)]
    else
        return Higgs.returningAfterFoundering[math.random(#Higgs.returningAfterFoundering)]
    end
end

return Dialogue