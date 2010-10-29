dofile("helptext.lua")

-- credit to the devs (ray I assume) for making this function.
-- I would've used the original but I needed to change one or 2 lines for it to work nicely with my plugin.
local function popuphelp()
	local cancelbutton = iup.stationbutton{title="Close",
		action=function()
			TargetTools.ShowHelp()
			return iup.CLOSE
		end}

	local text = iup.stationhighopacitysubmultiline{readonly="YES", expand="YES", value=""}

	local dlg = iup.dialog{
		iup.hbox{
			iup.fill{},
			iup.vbox{
				iup.fill{},
				iup.stationhighopacityframe{
					iup.vbox{
						text,
						iup.stationhighopacityframebg{
							iup.hbox{
								iup.fill{},
								cancelbutton,
								iup.fill{},
							},
						},
					},
					size="THREEQUARTERxTHREEQUARTER",
					expand="NO",
				},
				iup.fill{},
			},
			iup.fill{},
		},
		defaultesc = cancelbutton,
		defaultenter = cancelbutton,
		border="NO",
		resize="NO",
		menubox="NO",
		bgcolor="0 0 0 128 *",
		fullscreen = "YES",
		topmost="YES",
	}
	function dlg:show_cb()
		text.caret = 0
	end
	function dlg:Open(helptext)
		text.value = helptext
		text.scroll = "TOP"
		PopupDialog(dlg, iup.CENTER, iup.CENTER)
	end
	return dlg
end

local helpdlg = popuphelp()
helpdlg:map()


local helptext1 = iup.label{title="Here is a list of commands available in the Target Tools pack."}
local helptext2 = iup.label{title="Select one and click Info to bring up a dialog explaining how it works."}

local names = {
	"GroupAttacked",
	"GuildAttacked",
	"GuildReady",
	"GroupReady",
	"GuildTarget",
	"GroupTarget",
	"TargetFront",
	"TargetNextTurret",
	"TargetPrevTurret",
	"TargetParent",
	"TargetCargo",
	"TargetPlayer",
	"TargetShip",
}
local namelist = iup.list{dropdown="YES"}

for i,v in ipairs(names) do namelist[i] = v end

local close = iup.stationbutton{title="Close", expand="HORIZONTAL"}
local bindbutton = iup.stationbutton{title="Bind", active="NO"}
local helpbutton = iup.stationbutton{title="Info", expand="HORIZONTAL", action=function()
	close:action()
	helpdlg:Open(TargetTools.helptext[namelist[namelist.value]])
end}
local modtext = iup.text{size=90, active="NO"}
local bindtext = iup.text{size=20, action=function(self, k, val)
	if #val > 1 then
		return iup.IGNORE
	elseif #val < 1 then
		bindbutton.active="NO"
		self.fgcolor="255 255 255"
	else
		bindbutton.active="YES"
		local bind = gkinterface.GetCommandForKeyboardBind(k)
		self.fgcolor=not bind and "181 247 181" or "247 181 181"
	end
end}
local bindlabel = iup.label{title="Bind Key:"}
local modlabel = iup.label{title="Modifier:", fgcolor="160 160 160"}

local binds_box = iup.vbox{
	iup.label{title="Binds:"},
	iup.hbox{namelist, helpbutton, gap=5, alignment="ACENTER"},
	iup.hbox{modlabel, modtext, bindlabel, bindtext, bindbutton, gap=5, alignment="ACENTER"},
	gap=7,
	alignment="ALEFT",
	margin="2x2",
	expand="YES",
}

function namelist:action(s, i, v)
	modtext.value = ""
	bindtext.value = ""
	bindtext.fgcolor = "255 255 255"
	bindbutton.active = "NO"
	if s == "TargetShip" or s == "TargetPlayer" or s == "TargetCargo" then
		modlabel.fgcolor="255 255 255"
		modtext.active = "YES"
	else
		modlabel.fgcolor="160 160 160"
		modtext.active="NO"
	end
end

function bindbutton:action()
	if bindtext.value == "" then return end
	local key = gkinterface.GetInputCodeByName(bindtext.value)
	local name = namelist[namelist.value]
	if modtext.value == "" then
		gkinterface.BindCommand(key, name)
	else
		local modname = name.."_"..modtext.value:gsub(" ", "_")
		gkinterface.GKProcessCommand("alias "..modname.." \""..name.." '"..modtext.value.."'\"")
		gkinterface.BindCommand(key, modname)
	end
	bindtext.value = ""
	bindtext.fgcolor = "255 255 255"
	modtext.value = ""
	self.active = "NO"
end


local retarget_toggle = iup.stationtoggle{title="ReTarget Is Active", action=function(self,v)
	TargetTools.ReTarget.active=self.value=="ON"
	self.fgcolor = v==1 and tabunseltextcolor or "192 192 192"
	gkini.WriteString("targettools", "retarget", self.value)
end}


local retarget_box = iup.vbox{
	iup.label{title="ReTarget:"},
	iup.stationbutton{title="Info", expand="HORIZONTAL", action=function() close:action() helpdlg:Open(TargetTools.helptext["ReTarget"]) end},
	iup.fill{},
	retarget_toggle,
	gap=7,
	margin="2x2",
	expand="YES",
}


local main = iup.vbox{
	iup.hbox{
		iup.pdarootframe{binds_box, expand="YES"},
		iup.pdarootframe{retarget_box, expand="YES"},
		gap=8,
	},
	iup.pdarootframe{close},
	gap=8,
	expand="NO",
}


local dlg = iup.dialog{
	iup.vbox{
		iup.fill{},
		iup.hbox{iup.fill{}, helptext1, iup.fill{}},
		iup.hbox{iup.fill{}, helptext2, iup.fill{}},
		iup.fill{size=10},
		iup.hbox{
			iup.fill{},
			main,
			iup.fill{},
		},
		iup.fill{size=10},
		iup.label{title=""},
		iup.label{title=""},
		iup.fill{},
	},
	defaultesc=close,
	bgcolor="0 0 0 128 *",
	fullscreen="YES",
	border="NO",
	resize="NO",
    maxbox="NO",
    minbox="NO",
    menubox="NO",
    topmost="YES",
    show_cb=function() FadeControl(helptext1, 6, 6, 0) FadeControl(helptext2, 6, 6, 0) end,
    hide_cb=function() FadeStop(helptext1) FadeStop(helptext2) end,
}
dlg:map()


function close:action()
	HideDialog(dlg)
end

function TargetTools.ShowHelp()
	retarget_toggle.value = TargetTools.ReTarget.active and "ON" or "OFF"
	retarget_toggle.fgcolor = TargetTools.ReTarget.active and tabunseltextcolor or "192 192 192"
	ShowDialog(dlg)
end

RegisterUserCommand("TargetTools", TargetTools.ShowHelp)
	