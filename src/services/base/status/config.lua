local config = {}

config.code = {
    SUCCESS = 1,
    FAILED = 2,
    TIMEOUT = 3,
    ERROR_SERVICE = 4,
    ERROR_METHOD = 5,
    ERROR_PARAM = 6
}

config.serviceName = {
    -- private

    -- public
    login = "login"
}

-- 公开方法
config.servicePublicMethod = {
    [config.serviceName.login] = {
        "login"
    }
}

-- 公开服务
config.publicService = {
    [1] = config.serviceName.login
}

return config