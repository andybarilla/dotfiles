function tvssh
    ssh -L 3000:localhost:3000 -L 3088:localhost:3088 -L 8079:localhost:8079 -L 8083:localhost:8083 -L 8091:localhost:8091 -L 4443:localhost:4443 apbmbp
end
