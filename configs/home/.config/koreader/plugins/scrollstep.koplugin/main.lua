--[[--
Adds Vim/Sioyek-style navigation to the reader and File Manager.

Reader Ctrl+J/K pans 30% of the screen in scroll mode and turns one page in
page mode/PDFs. History keeps per-book letter shortcuts except reserved `f`,
adds Ctrl+J/K list paging, and uses `f` to return to the File Browser. The
File Manager reserves `h` for opening History while keeping its other per-item
letter shortcuts.

@module koplugin.ScrollStep
--]]--

local Dispatcher = require("dispatcher")  -- luacheck: ignore
local logger = require("logger")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local STEP_FRACTION = 0.3

local ScrollStep = WidgetContainer:extend{
    name = "scrollstep",
    is_doc_only = false,
}

function ScrollStep:onDispatcherRegisterActions()
    Dispatcher:registerAction("scroll_step_down", {
        category = "none",
        event = "ScrollStepDown",
        title = _("Scroll down 30% of the screen"),
        reader = true,
    })
    Dispatcher:registerAction("scroll_step_up", {
        category = "none",
        event = "ScrollStepUp",
        title = _("Scroll up 30% of the screen"),
        reader = true,
    })
end

local function withoutShortcut(shortcuts, reserved)
    local filtered = {}
    for _, shortcut in ipairs(shortcuts) do
        if shortcut ~= reserved then
            table.insert(filtered, shortcut)
        end
    end
    return filtered
end

function ScrollStep:configureHistoryMenu(menu)
    if not menu then return end

    -- Keep History's per-book shortcuts, but reserve F for returning to the
    -- File Browser. Ctrl+J/K do not collide with the plain J/K item shortcuts.
    menu.item_shortcuts = withoutShortcut(menu.item_shortcuts, "F")
    menu.is_enable_shortcut = true
    menu.key_events.SelectByShortCut = { { menu.item_shortcuts } }
    menu.key_events.ScrollStepHistoryNextPage = { { "Ctrl", "J" } }
    menu.key_events.ScrollStepHistoryPrevPage = { { "Ctrl", "K" } }
    menu.key_events.ScrollStepHistoryFileManager = {
        { "F" },
        { "Ctrl", "F" },
    }

    menu.onScrollStepHistoryNextPage = function(history_menu)
        logger.dbg("ScrollStep: paging History forward")
        history_menu:onNextPage()
        return true
    end
    menu.onScrollStepHistoryPrevPage = function(history_menu)
        logger.dbg("ScrollStep: paging History backward")
        history_menu:onPrevPage()
        return true
    end
    local ui = self.ui
    menu.onScrollStepHistoryFileManager = function(history_menu)
        logger.dbg("ScrollStep: leaving History for File Browser")
        history_menu:onCloseAllMenus()
        if ui.document then
            ui:onHome()
        end
        return true
    end
    menu:updateItems()
end

function ScrollStep:configureFileManagerMenu(menu)
    if not menu then return end

    -- Reserve H for History, retaining all other per-file letter shortcuts.
    menu.item_shortcuts = withoutShortcut(menu.item_shortcuts, "H")
    menu.key_events.SelectByShortCut = { { menu.item_shortcuts } }
    menu.key_events.ScrollStepShowHistory = { { "H" } }
    local history = self.ui.history
    menu.onScrollStepShowHistory = function()
        logger.dbg("ScrollStep: opening History from File Manager")
        history:onShowHist()
        return true
    end
    menu:updateItems()
end

function ScrollStep:configureTocMenu(menu)
    if not menu then return end

    menu.key_events.ScrollStepTocNextPage = { { "Ctrl", "J" } }
    menu.key_events.ScrollStepTocPrevPage = { { "Ctrl", "K" } }
    menu.onScrollStepTocNextPage = function(toc_menu)
        logger.dbg("ScrollStep: paging Table of Contents forward")
        toc_menu:onNextPage()
        return true
    end
    menu.onScrollStepTocPrevPage = function(toc_menu)
        logger.dbg("ScrollStep: paging Table of Contents backward")
        toc_menu:onPrevPage()
        return true
    end
end

function ScrollStep:installTocBindings()
    local toc = self.ui and self.ui.toc
    if not toc or toc._scrollstep_original_onShowToc then return end

    local original_onShowToc = toc.onShowToc
    toc._scrollstep_original_onShowToc = original_onShowToc
    toc.onShowToc = function(toc_module, ...)
        local result = original_onShowToc(toc_module, ...)
        self:configureTocMenu(toc_module.toc_menu)
        return result
    end
    self:configureTocMenu(toc.toc_menu)
end

function ScrollStep:installHistoryBindings()
    local history = self.ui and self.ui.history
    if not history or history._scrollstep_original_onShowHist then return end

    local original_onShowHist = history.onShowHist
    history._scrollstep_original_onShowHist = original_onShowHist
    history.onShowHist = function(history_module, ...)
        local result = original_onShowHist(history_module, ...)
        self:configureHistoryMenu(history_module.booklist_menu)
        return result
    end

    -- Also cover plugin reloads while History is already open.
    self:configureHistoryMenu(history.booklist_menu)
end

function ScrollStep:init()
    self:installHistoryBindings()
    if self.ui.document then
        self:installTocBindings()
        self:onDispatcherRegisterActions()
    else
        self.ui:registerPostInitCallback(function()
            self:configureFileManagerMenu(self.ui.file_chooser)
        end)
    end
end

function ScrollStep:scrollStep(direction)
    local ui = self.ui
    if not ui then return end
    if ui.rolling then
        if ui.view.view_mode == "scroll" then
            ui.rolling:_gotoPos(ui.rolling.current_pos + direction * STEP_FRACTION * ui.dimen.h)
        else
            ui.rolling:onGotoViewRel(direction)
        end
    elseif ui.paging then
        ui.paging:onGotoViewRel(direction)
    end
end

-- Dispatcher path (bare reader): used by the hotkeys bindings.
function ScrollStep:onScrollStepDown()
    self:scrollStep(1)
    return true
end

function ScrollStep:onScrollStepUp()
    self:scrollStep(-1)
    return true
end

return ScrollStep
