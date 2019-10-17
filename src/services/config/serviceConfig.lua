local config = {}

config.serviceName = {
    -- private

    -- public
    login = "login"
}

-- 公开方法
config.servicePublicMethod = {
    [config.serviceName.login] = {}
}

-- 公开服务
config.publicService = {
    [1] = config.serviceName.login
}

return config