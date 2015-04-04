require 'hue'
require 'color'
require 'unicode'
require 'colorable'

class AlexaPhilipsHue

  HUE_CLIENT = Hue::Client.new
  COLORS = Color::RGB.new
  #COLORABLE = Colorable::Color.new

  BEDROOM_LIGHTS = ["Master Bedroom Closet West", "Master Bedroom Closet East", "Master Bedroom East", "Master Bedroom South", "Master Bedroom West"]
  MOVIE_LIGHTS = ["Movie W", "Movie NE", "Movie E", "Movie SE", "Movie NW", "Movie SW"]
  HALLWAY_LIGHTS = ["Hallway South", "Hallway North"]
  OFFICE_LIGHTS = ["Office South", "Office North", "Office East", "Office West"]
  DININGROOM_LIGHTS = ["Dining Room SE", "Dining Room NW", "Dining Room NE", "Dining Room SW"]
  OTHER_LIGHTS = ["Entry", "Lamp"]
  #SATURATION_MODIFIERS = {dim: 200, lighter: 200, light: 200, darker: 255, dark: 255, darkest: 200}

  attr_reader :lastGroup
  attr_reader :colorNames

  def initialize
    puts "\n\nLoading all the Color Names"
    LoadColorNames("./data/colorNames.txt")

    puts "*** Listing Hue Bridge Light Groups ***"
    groups = HUE_CLIENT.groups
    groups.each do |group|
      puts group.name
    end
    puts "*** End Hue Bridge Light Groups ***"
    puts

    puts "*** Checking for Groups to Add ***"
    all = OFFICE_LIGHTS + BEDROOM_LIGHTS + MOVIE_LIGHTS + HALLWAY_LIGHTS + OTHER_LIGHTS + DININGROOM_LIGHTS
    CreateGroup("Living", MOVIE_LIGHTS)
    CreateGroup("Movie", MOVIE_LIGHTS)
    CreateGroup("Office", OFFICE_LIGHTS)
    CreateGroup("Bedroom", BEDROOM_LIGHTS)
    CreateGroup("Hallway", HALLWAY_LIGHTS)
    CreateGroup("Dining", DININGROOM_LIGHTS)
    CreateGroup("Other", OTHER_LIGHTS)
    CreateGroup("All", all)
    puts "*** End Checking for Groups to Add ***"

    puts "Setting the last spoken group to 'All'"
    @lastGroup = "All"
  end

  def ProcessLights(command)
    puts "Accessing the Process Lights Function of AlexaPhipsHue"
    puts "** Last Group = " + lastGroup + "**"

    matchValue = command.match(/(turn (on|off).*lights*|lights*.*(on|off))/)
    if (matchValue != nil)
      onOff = command.match(/(on|off)/).captures
      SetGroupPower(command, onOff)
    end

    matchValue = command.match(/set.*(brightness|saturation)/)
    if (matchValue != nil)
      match = command.match(/(brightness|saturation) to (.*)/)
      if (match != nil)
        levelWords = match[1].to_s
        puts "Level Words: " + levelWords
        SetGroupLevel(command, levelWords)
      else
        puts "Could not make out level words"
      end
    else
      puts "MatchValue for (brightness|saturation) was nil"
    end

    matchValue = command.match(/(dim|lower|bright[eo]n|raise)/)
    if (matchValue != nil)
      adjustmentWord = matchValue[1].to_s
      AdjustGroupBrightness(command, adjustmentWord)
    else
      puts "MatchValue for (dim|brighten) was nil"
    end

    matchValue = command.match(GetColorMatchString())
    if (matchValue != nil)
      color = matchValue[4].to_s
      color = color.gsub(" ", "")
      puts "Found this Color: " + color
      ChangeGroupToColor(command, color)
    else
      puts "MatchValue for Color Match was nil"
    end
  end

  def ChangeGroupToColor(command, color)
    groupName = GetGroupName(command)
    group = GetLightGroup(groupName)

    puts color
    if (group != nil)
      rgb = Color::RGB.by_name(color.to_sym)
      puts rgb.r
      puts rgb.g
      puts rgb.b

      hsl = rgb.to_hsl
      hue = hsl.h * 65535
      lum = hsl.l * 255
      sat = hsl.s * 255

      puts "Hue: " + hue.to_s
      puts "Sat: " + sat.to_s
      puts "Lum: " + lum.to_s

      group.set_state({:hue => hue.to_i, :saturation => sat.to_i, :luminance => lum.to_i})
    end
  end 

  def GetColorMatchString()
    return "set (the )?(.*) lights to (the color )?(" + colorNames[0] + ")"
  end

  def AdjustGroupBrightness(command, levelType)
    groupName = GetGroupName(command)
    group = GetLightGroup(groupName)

    if group == nil
      puts "Could not find a group to Adjust the brightness for"
      return
    end

    brightness = group.brightness
    adjustment = 50;
    limit = 255

    puts "LevelType: " + levelType

    if levelType == "dim" || levelType == "lower"
      adjustment *= -1
      limit = 0
      brightness = brightness + adjustment < limit ? limit : brightness + adjustment;
    else
      brightness = brightness + adjustment > limit ? limit : brightness + adjustment;
    end

    group.set_state({:brightness => brightness})
  end

  def SetGroupLevel(command, levelType)
    groupName = GetGroupName(command)
    group = GetLightGroup(groupName)

    if (group == nil)
      return
    end

    match = command.match(/(brightness|saturation) to (.*)/)
    valueWords = match[2].to_s
    valueNumber = valueWords.in_numbers

    puts "Value Words: " + valueWords
    puts "Value Number: " + valueNumber.to_s

    puts "Level Type: " + levelType
    if levelType.scan(/brightness/).length > 0
      #group.brightness = valueNumber
      group.set_state({:brightness => valueNumber})
    elsif levelType.scan(/saturation/).length > 0
      #group.saturation = valueNumber
      group.set_state({:saturation => valueNumber})
    end
  end

  def SetGroupPower(command, onOff)
    groupName = GetGroupName(command)
    group = GetLightGroup(groupName)

    if group == nil
      puts "Group " + groupName + " not found!"
      return
    else
      puts "Found Group at Hub: " + group.name
    end

    if onOff[0] == "on"
      puts "Setting group to ON"
      group.on!
    elsif onOff[0] == "off"
      puts "Setting group to OFF"
      group.off!
    else
      puts "Didn't find the on/off condition"
    end

    @lastGroup = groupName
  end

  def GetGroupName(command)
    matches = command.match(/(all) the lights*/)
    if (matches != nil)
      puts "Found 'All' for groupName"
      return "All"
    else
      puts "Skipping 'All' for groupName"
    end

    groupName = "All"
    matches = command.match(/([^\s]*)( room)? lights*/)
    if (matches != nil && matches.length == 3)
      groupName = matches[1].to_s
    end

    groupName = Unicode::capitalize(groupName)
    if groupName == nil || groupName == ""
      puts "No groupName"
      return "All"
    else
      puts "Found Group Name: " + groupName
      @lastGroup = groupName
      return groupName
    end
  end

  def GetLightGroup(groupName)
    groups = HUE_CLIENT.groups
    puts "Number of Groups: " + groups.length.to_s

    #puts "Requested Group: " + groupName
    #puts "Requested Group: " + Unicode::capitalize(groupName[1])

    groups.each do |g|
      puts "Each - " + g.name
      if g.name == groupName
        puts "Found Group: " + groupName
        puts g.name
        puts g.id

        g.lights.each { |l| puts l.name }
        #puts g.lights

        return g
      end
    end
  end

  def DestroyGroup(groupName)
    group = GetLightGroup(groupName)
    group.destroy!
  end

  def CreateGroup(groupName, lightList)
    groups = HUE_CLIENT.groups

    groups.each do |group|
      if group.name == groupName
        puts groupName + ": Group Already Exists"
        return
      end
    end

    group = HUE_CLIENT.group
    group.name = groupName
    group.lights = HUE_CLIENT.lights.select{|light| lightList.include?(light.name)}
    group.new?
    group.create!
  end

  def LoadColorNames(fileName)
    @colorNames = File.readlines(fileName)
  end
end

