--!strict
-- Read-only markers. Every descendant is decorative and passes map input through.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Players=game:GetService("Players")
local Theme=require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Layout=require(ReplicatedStorage.Shared.Util.BuildingMarkerLayout)
local State=require(script.Parent.MapContextState)
local Markers={}
function Markers.Start(stage: Frame,map: any,gui: ScreenGui,project: (number,number)->Vector2?,changed: BindableEvent)
	if stage:FindFirstChild("BuildingMarkers") then return end
	local layer=Instance.new("Frame");layer.Name="BuildingMarkers";layer.Size=UDim2.fromScale(1,1)
	layer.BackgroundTransparency=1;layer.Active=false;layer.ClipsDescendants=true;layer.ZIndex=2;layer.Parent=stage
	local tooltip=Instance.new("TextLabel");tooltip.Name="BuildingHover";tooltip.Active=false
	tooltip.BackgroundColor3=Theme.Colors.panel;tooltip.TextColor3=Theme.Colors.textPrimary
	tooltip.AutomaticSize=Enum.AutomaticSize.Y;tooltip.Size=UDim2.fromOffset(190,34);tooltip.TextSize=12;tooltip.TextWrapped=true;tooltip.Visible=false;tooltip.ZIndex=3;tooltip.Parent=layer
	Theme.applyText(tooltip,"Caption");tooltip.BackgroundTransparency=.08;tooltip.TextColor3=Theme.Colors.textPrimary
	local corners=Instance.new("UICorner");corners.CornerRadius=UDim.new(0,4);corners.Parent=tooltip
	local anchors,views,rows={},{},{}
	local kinds={"Farm","Town","Castle","Capital"}
	local function frame(parent: Instance,name: string,x: number,y: number,w: number,h: number,color: Color3,rotation: number?): Frame
		local f=Instance.new("Frame");f.Name=name;f.Active=false;f.BorderSizePixel=0;f.BackgroundColor3=color
		f.ZIndex=2;f.Position=UDim2.fromScale(x,y);f.Size=UDim2.fromScale(w,h);f.Rotation=rotation or 0;f.Parent=parent;return f
	end
	for _, province in map.territories do
		local x,y,unit=Layout.Anchor(province.polygon);local cx,cy=require(ReplicatedStorage.Shared.Util.MapGeometry).Centroid(province.polygon);anchors[province.id]={x=x,y=y,unit=unit,cx=cx,cy=cy}
		views[province.id]={}
		for index,kind in kinds do
			local root=frame(layer,province.id.."_"..kind,0,0,0,0,Theme.Colors.panel)
			root.BackgroundTransparency=1;root.Visible=false;root:SetAttribute("BlocksMapInput",false)
			local art=frame(root,"Silhouette",0,0,1,1,Theme.Colors.panel);art.BackgroundTransparency=1
			local ink=Theme.Colors.textPrimary
			if kind=="Farm" then
				for _,i in {.3,.5,.7} do frame(art,"Stalk",i,.22,.065,.65,ink);frame(art,"Grain",i-.09,.22,.14,.18,ink,-25) end
			elseif kind=="Town" then
				for _,i in {.12,.43,.72} do frame(art,"House",i,.47,.2,.35,ink);frame(art,"Roof",i+.035,.33,.14,.2,ink,45) end
			elseif kind=="Castle" then
				frame(art,"Wall",.15,.4,.7,.42,ink)
				for _,i in {.13,.43,.73} do frame(art,"Battlement",i,.24,.14,.25,ink) end
				frame(art,"Gate",.42,.62,.16,.2,Theme.Colors.panel)
			else
				frame(art,"CrownBand",.15,.65,.7,.16,Theme.Colors.accentGold)
				for _,i in {.17,.45,.73} do frame(art,"CrownPoint",i,.25,.12,.47,Theme.Colors.accentGold,if i<.3 then -15 elseif i>.6 then 15 else 0) end
				frame(art,"Gem",.43,.12,.15,.15,Theme.Colors.accentGold,45)
			end
			local presence=frame(root,"Presence",.3,.3,.4,.4,if kind=="Capital" then Theme.Colors.accentGold else ink)
			presence.Rotation=if kind=="Farm" or kind=="Capital" then 45 else 0
			local badge=Instance.new("TextLabel");badge.Name="Level";badge.Active=false;badge.ZIndex=2;badge.Size=UDim2.fromOffset(11,11)
			badge.Position=UDim2.fromScale(.6,.58);badge.TextScaled=true;badge.TextSize=11;badge.BackgroundColor3=Theme.Colors.panel;badge.TextColor3=ink;badge.Parent=root;Theme.applyText(badge,"Caption");badge.BackgroundTransparency=0
			local repair=Instance.new("TextLabel");repair.Name="Repair";repair.ZIndex=2;repair.Active=false;repair.BackgroundTransparency=1
			repair.Size=UDim2.fromScale(.4,.4);repair.Position=UDim2.fromScale(0,0);repair.Text="!";repair.TextColor3=Theme.Colors.danger;repair.TextSize=12;repair.Parent=root;Theme.applyText(repair,"Caption");repair.TextScaled=true;repair.BackgroundTransparency=.15;repair.BackgroundColor3=Theme.Colors.panel
			local crack=frame(root,"Crack",.46,.2,.06,.6,Theme.Colors.panel,25)
			views[province.id][index]={root=root,art=art,presence=presence,badge=badge,repair=repair,crack=crack,kind=kind}
		end
	end
	local function hover()
		tooltip.Visible=false
		if not gui.Enabled or not stage.Visible or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
		local cursor=UIS:GetMouseLocation()-GuiService:GetGuiInset()
		for _,object in Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(cursor.X,cursor.Y) do
			if object~=stage and not object:IsDescendantOf(stage) and (object:IsA("TextButton") or object:IsA("ImageButton") or object.Active) then return end
		end
		for id,group in views do for _,view in group do
			local root=view.root;local p,s=root.AbsolutePosition,root.AbsoluteSize
			if root.Visible and cursor.X>=p.X and cursor.X<=p.X+s.X and cursor.Y>=p.Y and cursor.Y<=p.Y+s.Y then
				tooltip.Text=view.description;tooltip.Visible=true
				tooltip.Position=UDim2.fromOffset(math.clamp(cursor.X-stage.AbsolutePosition.X+10,0,math.max(0,stage.AbsoluteSize.X-190)),math.clamp(cursor.Y-stage.AbsolutePosition.Y+12,0,math.max(0,stage.AbsoluteSize.Y-tooltip.AbsoluteSize.Y)))
				return
			end
		end end
	end
	local function render()
		local viewport=stage:FindFirstChild("MapView") :: GuiObject
		local lower=viewport.AbsolutePosition-stage.AbsolutePosition
		local upper=lower+viewport.AbsoluteSize
		local presenting={};for _,war in State.military.wars or {} do if war.phase=="present" then presenting[war.targetTerritoryId]=true end end
		for id,group in views do
			local row=rows[id];local anchor=anchors[id]
			local name=stage:FindFirstChild("ProvinceName_"..id) :: TextLabel
			local namePoint=project(anchor.cx,anchor.cy)
			if namePoint then name.Position=UDim2.fromOffset(namePoint.X,namePoint.Y) end
			local occupied=false
			if row then for _,kind in kinds do if (row[string.lower(kind).."Level"] or 0)>0 or row.ruin then occupied=true end end end
			local center=project(anchor.x,anchor.y);local extent=project(anchor.x+anchor.unit,anchor.y)
			local extentSize=if center and extent then (extent-center).Magnitude else 0
			if occupied and extentSize>=12 and center then
				local offset=math.min(extentSize,32)*1.3+10
				local nameY=if center.Y-offset>=lower.Y+12 then center.Y-offset else center.Y+offset
				if nameY<upper.Y-12 then name.Position=UDim2.fromOffset(center.X,nameY) end
			end
			for index,view in group do
				local level=if row then row[string.lower(view.kind).."Level"] or 0 else 0
				local ruin=row and view.kind=="Capital" and row.ruin==true
				local damaged=row and row.damage and row.damage[view.kind]==true
				local x,y=Layout.Slot(anchor.x,anchor.y,anchor.unit,index)
				local p=project(x,y);local edge=project(x+anchor.unit,y)
				local size=if p and edge then (edge-p).Magnitude else 0
				size=math.min(size,32)
				view.root.Visible=(level>0 or ruin==true) and p~=nil and size>=2 and p.X>=lower.X+size*.5 and p.Y>=lower.Y+size*.5 and p.X<upper.X-size*.5 and p.Y<upper.Y-size*.5
				if p then view.root.Position=UDim2.fromOffset(p.X-size*.5,p.Y-size*.5);view.root.Size=UDim2.fromOffset(size,size) end
				local detail=size>=12 and not presenting[id]
				view.art.Visible=detail;view.presence.Visible=not detail;view.badge.Visible=detail and size>=12 and not ruin
				view.badge.TextScaled=true;view.badge.Text=tostring(level);view.badge.TextColor3=if level==5 then Theme.Colors.accentGold else Theme.Colors.textPrimary
				view.repair.Visible=damaged==true and detail;view.crack.Visible=(damaged==true or ruin==true) and detail
				for _,part in view.art:GetChildren() do if part:IsA("Frame") then part.BackgroundTransparency=if damaged or ruin then .6 else 0; if part.Name=="Gem" then part.Visible=not ruin end end end
				view.presence.BackgroundTransparency=if damaged or ruin then .55 else 0
				view.description=if ruin then "Capital ruin · Inert · No bonuses" else view.kind.." · Level "..level..(if damaged then " · Repair required" elseif level==5 then " · Max" else " · Healthy")
			end
		end
		hover()
	end
	State.Changed.Event:Connect(function(system,kind)
		if system=="buildings" or system=="match" then rows={};for _,row in State.buildings.provinces or {} do rows[row.territoryId]=row end;render()
		elseif system=="military" then render() end
	end)
	changed.Event:Connect(render)
	Theme.PresentationChanged.Event:Connect(render)
	UIS.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement then hover() end end)
	for _,row in State.buildings.provinces or {} do rows[row.territoryId]=row end
	render()
end
return Markers
