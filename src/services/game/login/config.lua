local config = {}

config.code = {
    SUCCESS = 1,
    FAILED = 2,
    ERROR_ACCOUNT = 3,
    ERROR_LOGIN_TYPE = 4,
    ERROR_USER = 5,
    ERROR_SAVE = 6,
}

config.errorStr = {
    [config.code.SUCCESS] = "Login Success",
    [config.code.FAILED] = "Login Failed",
    [config.code.ERROR_ACCOUNT] = "Account Or Password Error",
    [config.code.ERROR_LOGIN_TYPE] = "Unknown Login Type",
    [config.code.ERROR_USER] = "Make User Error",
    [config.code.ERROR_SAVE] = "Save Data Error"
}

config.loginType = {
    GUEST = 1
}