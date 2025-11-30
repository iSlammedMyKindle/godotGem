using Nefarius.ViGEm.Client.Targets.Xbox360;

namespace Constants
{
    public static class Mappings
    {
        // We don't have anymore buttons above index 14, so these will be used to determine which axis is being detected.
        public static readonly Dictionary<byte, Xbox360Property> ANALOG_MAP = new()
        {
            {15, Xbox360Axis.LeftThumbX},
            {16, Xbox360Axis.LeftThumbY},
            {17, Xbox360Axis.RightThumbX},
            {18, Xbox360Axis.RightThumbY},
            {19, Xbox360Slider.LeftTrigger},
            {20, Xbox360Slider.RightTrigger}
        };
    }
}