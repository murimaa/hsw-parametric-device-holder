/* [Preferences] */
// Show device and HSW mockup. Disable for printing.
Preview = true;

Device_Width = 169.5;
Device_Height = 240;
Device_Thickness = 7.5;
// Gap between holder and device, so its not too tight
Device_Clearance = 0.5;

Bottom_Left = true;
Bottom_Right = true;
Top_Right = true;
Top_Left = true;
Left = true;
Right = true;
Bottom = true;
Top = true;

/* [Adjustments] */
Holder_Thickness = 3;
Holder_Width = 12;
Lip_Size=3;
Lip_Thickness=4;

// Thickness of the back plate between honeycomb wall and the holder piece. Needs to be > 0. Increasing value makes a gap between the device and honeycomb wall, useful if for example you want cable routing behind the device.
Back_Thickness = 3;

// Affects edge pieces only (not corners). Angles the holders so they apply a bit of clamping force. Useful for thick devices especially if corner pieces are not used. Recommend a small value (0-5).
Clamp_Angle = 0;

// Empty HSW insert is 20mm.
Hex_Insert_Size=20;
// Subtracted from Hex Insert Size for tolerance.
Hex_Insert_Tolerance = 0.0;
// Depth of the HSW insert. 8mm works for empty insert.
Hex_Insert_Depth=8;

/* [Hidden] */
// Do not edit
$hsw_insert_horizontal_distance = 40.88;
$hsw_insert_vertical_distance = 23.60;

$corner_horizontal_offset = (Device_Width %  $hsw_insert_horizontal_distance) / 2;
$corner_vertical_offset = (Device_Height % $hsw_insert_vertical_distance) / 2;

$hsw_cells_horizontal = floor(Device_Width / $hsw_insert_horizontal_distance);
$hsw_cells_vertical = floor(Device_Height / $hsw_insert_vertical_distance);

$horizontal_spacing = $corner_horizontal_offset + hexagon_radius(Hex_Insert_Size);
$vertical_spacing = $corner_vertical_offset + Hex_Insert_Size;

$part_layout_spacing = max($horizontal_spacing, $vertical_spacing) + 5;

color("orange") {
    if (Bottom_Left)
        corner_bottom_left(grid_position(1), grid_position(1));
    if (Top_Right)
        corner_top_right(grid_position(3), grid_position(3));
    if (Bottom_Right) 
        corner_bottom_right(grid_position(3), grid_position(1));
    if (Top_Left) corner_top_left(grid_position(1), grid_position(3));

    if (Bottom) edge_bottom(grid_position(2), grid_position(1));
    if (Top) edge_top(grid_position(2), grid_position(3));
    if (Left) edge_left(grid_position(1), grid_position(2));
    if (Right) edge_right(grid_position(3), grid_position(2));
}

if (Preview) {
    color("grey") device();
    color("lightgrey") translate([-$hsw_insert_horizontal_distance,-$hsw_insert_vertical_distance,0]) mirror([0,0,1]) honeycomb_pattern(cols=$hsw_cells_horizontal+2, rows=($hsw_cells_vertical+2)*2);
}

function grid_position(n) = Preview ? undef : (n-1) * $part_layout_spacing;
function hexagon_radius(size) = size/2/cos(180/6);
module single_honeycomb() {
  size=26;
  size_inner=20;
  radius_outer = hexagon_radius(size);
  radius_inner = hexagon_radius(size_inner);

  difference() {
    cylinder(h=8, r=radius_outer, $fn=6);
    translate([0,0,-1]) cylinder(h=10, r=radius_inner, $fn=6);
  }
}
module honeycomb_row(n) {
    single_honeycomb();
    if(n) {
        translate([$hsw_insert_horizontal_distance,0,0]) {
            honeycomb_row(n=n-1);
        }
    }
}
module honeycomb_pattern(cols, rows) {
    union() {
        honeycomb_row(cols);
        if(rows > 1) {
            is_even = rows % 2;
            translate([is_even * -$hsw_insert_horizontal_distance + $hsw_insert_horizontal_distance/2, $hsw_insert_vertical_distance/2,0]) honeycomb_pattern(cols, rows-1);
        }
    }
}

module device() {
translate([-$corner_horizontal_offset,-$corner_vertical_offset, Device_Clearance + Back_Thickness])
cube([ Device_Width,Device_Height,   Device_Thickness]);
}

module translate_to_vertical_edge() {
    translate([0, -($corner_vertical_offset +  Device_Clearance), 0]) {
        children();
    }
}
module translate_to_horizontal_edge() {
    translate([-($corner_horizontal_offset +  Device_Clearance), 0, 0]) {
        children();
    }
}
module translate_to_corner(z_plane) {
    translate_to_vertical_edge()
        translate_to_horizontal_edge()
            translate([0, 0, z_plane])
                children();
}
module corner_outline(width, height, thickness) {
    difference() {
        translate([-thickness, -thickness, 0]) square([width, height]);
        square([Device_Width + Device_Clearance * 2, Device_Height + Device_Clearance * 2]);
    }   
}

module hex_backplate() {
    hex_radius = hexagon_radius(Hex_Insert_Size-Hex_Insert_Tolerance);
    cylinder(h=Back_Thickness, r=hex_radius, $fn=6);

}
module rect_backplate(extrude_offset) {
    translate([-Holder_Thickness, 0, 0])
    cube([Holder_Thickness + extrude_offset + Device_Clearance, Holder_Width, Back_Thickness]);

}
// hex insert
module insert() {
    hex_radius = hexagon_radius(Hex_Insert_Size-Hex_Insert_Tolerance);
    
    translate([0,0,- Hex_Insert_Depth])
    rotate([0,0,0]) {
    difference() {
        cylinder(h=Hex_Insert_Depth, r=hex_radius, $fn=6);
        translate([0,0,-1]) cylinder(h=Hex_Insert_Depth+2, r=hex_radius-2, $fn=6);
        }
    }
}


module corner_bottom_left(x, y) {
    x = x == undef ? 0 : x;
    y = y == undef ? 0 : y;
    translate([x,y,0]) {
        insert();
        union() {
          hex_backplate();
          translate_to_corner(z_plane = 0)
            translate([0,-Holder_Thickness,0])
                rect_backplate(extrude_offset=$corner_horizontal_offset);
        }

        // corner

        translate_to_corner(z_plane =  Back_Thickness) {
            linear_extrude(height=Device_Thickness + Device_Clearance*2)

            corner_outline(width = Holder_Width, height = Holder_Width, thickness=Holder_Thickness);
        }

        // lip
        translate_to_corner(z_plane = Back_Thickness + Device_Thickness + Device_Clearance*2) {
            linear_extrude(height=Lip_Thickness)
            translate([Lip_Size, Lip_Size, 0])
            corner_outline(width = Holder_Width, height = Holder_Width, thickness=Holder_Thickness+Lip_Size);
        }
    }
}
module corner_bottom_right(x, y) {
    x = x == undef ? floor(Device_Width / $hsw_insert_horizontal_distance) * $hsw_insert_horizontal_distance : x;
    y = y == undef ? 0 : y;

    translate([x,y,0]) mirror([1,0,0]) corner_bottom_left();
}
module corner_top_left(x,y) {
    y = y == undef ? floor(Device_Height / $hsw_insert_vertical_distance) * $hsw_insert_vertical_distance : y;
    x = x == undef ? 0 : x;
  translate([0,y,0]) mirror([0,1,0]) corner_bottom_left();
}

module corner_top_right(x, y) {
    x = x == undef ? floor(Device_Width / $hsw_insert_horizontal_distance) * $hsw_insert_horizontal_distance : x;
    y = y == undef ? floor(Device_Height / $hsw_insert_vertical_distance) * $hsw_insert_vertical_distance : x;
    translate([x,y,0])
        mirror([1,0,0]) mirror([0,1,0])
            corner_bottom_left();
}

module edge(offset) {
        // edge holder has to be slightly longer to compensate for clamp angle
        extra_length = tan(Clamp_Angle) * Holder_Thickness;
        translate([-Holder_Width/2, offset, Back_Thickness]) {
        rotate([-Clamp_Angle,0,0]) {
            
            difference() {
                    cube([Holder_Width, Holder_Thickness + Lip_Size + Device_Clearance, Device_Thickness + Device_Clearance * 2 + Lip_Thickness + extra_length] );
                    translate([0, Holder_Thickness, 0]) 
                        cube([Holder_Width, Device_Clearance + Lip_Size, Device_Thickness + Device_Clearance * 2 + extra_length] );
            }
            
        }
    }
}
module edge_bottom(x, y) {
    x = x == undef ? round($hsw_cells_horizontal / 2) * $hsw_insert_horizontal_distance : x;
    y = y == undef ? 0 : y;
    
    translate([x, y, 0]) {
        insert();
        union() {
            hex_backplate();
            translate([-Holder_Width/2,0,0])
              rotate(-90) rect_backplate(extrude_offset=$corner_vertical_offset + Holder_Thickness);
        }
        edge(offset=-($corner_vertical_offset + Holder_Thickness + Device_Clearance));
    }
}

module edge_top(x, y) {
    x = x == undef ? round($hsw_cells_horizontal / 2) * $hsw_insert_horizontal_distance : x;
    y = y == undef ? floor(Device_Height / $hsw_insert_vertical_distance) * $hsw_insert_vertical_distance : y;
    mirror([0,1,0]) 
        edge_bottom(x, y=-y);
}

module edge_left(x=0, y) {
    x = x == undef ? 0 : x;
    y = y == undef ? round($hsw_cells_vertical / 2) * $hsw_insert_vertical_distance : y;
    
    translate([x, y, 0]) {
        insert();
        union() {
            hex_backplate();
            translate([0,-Holder_Width/2,0])
                mirror([1,0,0]) rect_backplate(extrude_offset=$corner_horizontal_offset + Holder_Thickness);
        }
        rotate(-90) 
            edge(offset=-($corner_horizontal_offset + Holder_Thickness + Device_Clearance));

    }
}

module edge_right(x, y) {
    x = x == undef ? $hsw_cells_horizontal * $hsw_insert_horizontal_distance : x;
    y = y == undef ? round($hsw_cells_vertical / 2) * $hsw_insert_vertical_distance : y;
    translate([x, y, 0]) {
        insert();
        union() {
            hex_backplate();
            translate([0,-Holder_Width/2,0])
                rect_backplate(extrude_offset=$corner_horizontal_offset + Holder_Thickness);
        }
        rotate(90)
            edge(offset=-($corner_horizontal_offset + Holder_Thickness + Device_Clearance));
    }
}
