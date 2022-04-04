adjusted = false;
function onCreate()
    makeLuaSprite("bg", "solo_bg", 0, 0);
    setProperty("bg.scrollFactor.x", 0);
    setProperty("bg.scrollFactor.y", 0);
    setProperty("bg.antialiasing", true);
    addLuaSprite("bg", false);

    --setProperty("boyfriend.scrollFactor.x", 0);
    --setProperty("boyfriend.scrollFactor.y", 0);
    defaultOpponentStrumX0 = -1000;
    defaultOpponentStrumX1 = -1000;
    defaultOpponentStrumX2 = -1000;
    defaultOpponentStrumX3 = -1000;
end

function onUpdate(elapsed)
    if (not adjusted) then
        setProperty("boyfriend.scrollFactor.x", 0);
        setProperty("boyfriend.scrollFactor.y", 0);

        setProperty("dad.alpha", 0);
        setProperty("gf.alpha", 0);

        for i = 0, 3, 1
        do
            setPropertyFromGroup('opponentStrums', i, 'x', -1000);
        end

        adjusted = true;
    end
end