if not clock then
    clock = {}
    if not clock.uv then
        clock.uv = require('luv')
    end
    function clock.now()
        -- Get the current high-resolution time in nanoseconds from a monotonic clock.
        -- return  clock.uv.clock_gettime("realtime").nsec/1e9
        return  clock.uv.hrtime()/1e9

    end

    function clock.sleep(seconds)
        clock.uv.sleep(seconds*1e3)
    end
end

-- Clock.apr = apr

