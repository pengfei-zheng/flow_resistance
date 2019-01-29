flow_resistance_Calculator = flow_resistance_Calculator or {}

require "temperature_density"
require "temperature_viscosity"
require "variable"
require "const"

local FlowRate = variable.flowrate
local Longitudinal_length
local flowchannel_diameter
local flowchannel_width
local flowchannel_length
local sectional_area_of_tubing
local shape_of_flowchannel = tubingparameter.shape_of_flowchannel
local Allvariable
local temperature = variable.temperature

function toSI() --换算为国际单位制
  FlowRate             = variable.flowrate / 10^6 / 60                --m^3/s
  Longitudinal_length  = tubingparameter.Longitudinal_length / 10^3   --m
  flowchannel_diameter = tubingparameter.flowchannel_diameter / 10^3  --m
  flowchannel_width    = tubingparameter.flowchannel_width / 10^3     --m 
  flowchannel_length   = tubingparameter.flowchannel_length / 10^3    --m
end
 
Allvariable = toSI()

function sectional_area_of_tubing() --计算流道截面积
  if     shape_of_flowchannel == "circle"    then
    sectional_area_of_tubing = math.pi * flowchannel_diameter * flowchannel_diameter / 4
  elseif shape_of_flowchannel == "rectangle" then
    sectional_area_of_tubing = flowchannel_width * flowchannel_length
  else   print("please confirm shape of flowchannel")
  end
  print("sectional_area_of_tubing = ", sectional_area_of_tubing, "m^2")
  
  return sectional_area_of_tubing
end

sectional_area_of_tubing = sectional_area_of_tubing()

function equivalent_diameter_Calculator() --计算当量直径
  -- equivalent_diameter = 4 * Hydraulic_radius 当量直径=4*水力直径
  -- Hydraulic_radius = sectional_area_of_tubing / perimeter  水力直径=过水断面面积/润湿周长
  if     shape_of_flowchannel == "circle"    then equivalent_diameter = flowchannel_diameter
  elseif shape_of_flowchannel == "rectangle" then equivalent_diameter = 4*sectional_area_of_tubing/(2*(flowchannel_width+flowchannel_length))
  else   print("please confirm shape of flowchannel")
  end

  return equivalent_diameter
end

function velocity_Calculator()  --计算流速
  local flow_velocity
  flow_velocity = FlowRate / sectional_area_of_tubing
  print("flow_velocity = ", flow_velocity,"m/s")
  
  return flow_velocity
end

function flow_resistance_Calculator.Reynolds_number() --计算雷诺数
  local density  = temperature_density[temperature]
  local velocity = velocity_Calculator()  --单位：m/s
  local equivalent_diameter = equivalent_diameter_Calculator()  --单位：m
  local viscosity = temperature_viscosity[temperature]  --单位：Pa·s
  Reynolds_number = density * velocity * equivalent_diameter / viscosity
  print("Reynolds_number = ", Reynolds_number)
  return Reynolds_number
end

function  friction_coefficient_Calculator() --计算摩擦系数
  local Reynolds_number = flow_resistance_Calculator.Reynolds_number()
  local friction_coefficient
  if Reynolds_number < 2300 then  --层流
    friction_coefficient = 64 / Reynolds_number --圆管层流计算公式
  ---[[
  elseif 2300 < Reynolds_number and Reynolds_number < 100000 then
    friction_coefficient = 0.316 / Reynolds_number^0.25           --Blasius公式       适用范围5*10^3～10^5
    friction_coefficient = 0.0056 + 0.500 / Reynolds_number^0.32  --顾毓珍公式                适用范围3*10^3～10^6
  elseif 1000000 < Reynolds_number then
    friction_coefficient =  5 --尼古拉兹公式
  --]]
  else 
  friction_coefficient = 64 / Reynolds_number
  print("***********************\nReynolds number > 2300\n***********************")
  end
  print("friction_coefficient =", friction_coefficient)
  return friction_coefficient
end

function frictional_head_loss()
  local frictional_head_loss
  local friction_coefficient = friction_coefficient_Calculator()
  local length = Longitudinal_length  --单位：米
  local diameter = equivalent_diameter_Calculator()
  local flow_velocity = velocity_Calculator()
  local g = const.gravitational_acceleration
  frictional_head_loss = friction_coefficient * length / diameter * flow_velocity * flow_velocity / 2  --范宁公式
  
  return frictional_head_loss
end

local flow_resistance = frictional_head_loss()

print("flow_resistance = ",flow_resistance,"kPa") --单位应该是Pa，但没有查出在哪步换算有问题，差10^3