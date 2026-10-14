local config = require("src.config")
local i18n = {}
local strings = {
    pl = {
        start_game = "Nowa gra", options = "Ustawienia", quit = "Wyjdź z gry",
        language_name = "Język: Polski", language = "Język",
        paused = "Pauza", resume = "Wznów grę", restart = "Restart od checkpointu",
        back_to_menu = "Menu główne", options_title = "Ustawienia",
        master_vol = "Głośność ogólna", sfx_vol = "Efekty dźwiękowe", music_vol = "Muzyka",
        screen_shake = "Wstrząsy ekranu", fullscreen = "Pełny ekran",
        surface_smoothing = "Wygładzanie obrazu",
        enabled = "Włączone", disabled = "Wyłączone", back = "Wróć",
        acorns = "ŻOŁĘDZIE", hp = "ZDROWIE", boss_name = "KOT",
        ammo_stone = "Kamienie", ammo_chestnut = "Kasztany", ammo_label = "AMUNICJA",
        journey = "CEL", objective_gather = "Zbierz %d żołędzi",
        objective_boss = "Pokonaj bossa", objective_home = "Dotrzyj do dziupli",
        controls_title = "Sterowanie", control_move = "Ruch", control_jump = "Skok",
        control_aim = "Celowanie", control_shoot = "Strzał", control_ammo = "Zmiana amunicji", control_pause = "Pauza",
        key_mouse = "MYSZ", key_lmb = "LPM", key_rmb = "PPM", key_space = "SPACJA",
        checkpoint_active = "Checkpoint aktywowany",
        boss_appeared = "Walka z bossem", boss_defeated = "Boss pokonany",
        hollow_need_more = "Brakuje %d żołędzi", hollow_enter = "W / SPACJA — Wejdź do dziupli",
        game_over = "Koniec gry", respawn_prompt = "Spróbuj ponownie",
        respawn_note = "Odrodzisz się przy ostatnim checkpoincie.",
        victory_title = "Wygrana", play_again = "Zagraj ponownie",
        stat_time = "Czas", stat_acorns = "Żołędzie", stat_enemies = "Pokonani wrogowie",
        checkpoint_ready = "Checkpoint aktywny", checkpoint_pending = "Checkpoint nieaktywny",
    },
    en = {
        start_game = "New game", options = "Settings", quit = "Quit game",
        language_name = "Language: English", language = "Language",
        paused = "Paused", resume = "Resume game", restart = "Restart from checkpoint",
        back_to_menu = "Main menu", options_title = "Settings",
        master_vol = "Master volume", sfx_vol = "Sound effects", music_vol = "Music",
        screen_shake = "Screen shake", fullscreen = "Fullscreen",
        surface_smoothing = "Surface smoothing",
        enabled = "On", disabled = "Off", back = "Back",
        acorns = "ACORNS", hp = "HEALTH", boss_name = "CAT",
        ammo_stone = "Stones", ammo_chestnut = "Chestnuts", ammo_label = "AMMO",
        journey = "OBJECTIVE", objective_gather = "Collect %d acorns",
        objective_boss = "Defeat the boss", objective_home = "Reach the hollow",
        controls_title = "Controls", control_move = "Move", control_jump = "Jump",
        control_aim = "Aim", control_shoot = "Shoot", control_ammo = "Switch ammo", control_pause = "Pause",
        key_mouse = "MOUSE", key_lmb = "LMB", key_rmb = "RMB", key_space = "SPACE",
        checkpoint_active = "Checkpoint activated",
        boss_appeared = "Boss fight", boss_defeated = "Boss defeated",
        hollow_need_more = "%d more acorns required", hollow_enter = "W / SPACE — Enter the hollow",
        game_over = "Game over", respawn_prompt = "Try again",
        respawn_note = "Respawn at the last checkpoint.",
        victory_title = "Victory", play_again = "Play again",
        stat_time = "Time", stat_acorns = "Acorns", stat_enemies = "Enemies defeated",
        checkpoint_ready = "Checkpoint active", checkpoint_pending = "Checkpoint inactive",
    },
}

function i18n.getLanguage()
    return strings[config.language] and config.language or "pl"
end

function i18n.toggleLanguage()
    config.language = i18n.getLanguage() == "pl" and "en" or "pl"
    return config.language
end

function i18n.get(key, ...)
    local val = strings[i18n.getLanguage()][key] or strings.pl[key] or key
    if select("#", ...) > 0 then return string.format(val, ...) end
    return val
end

return i18n
