Shader "Hidden/GLSL_PP"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		color_step ("ColorStep", float) = 5 
		PIXEL_RESOLUTION_X ("PIXEL_RESOLUTION_X", float) = 128
		PIXEL_RESOLUTION_Y ("PIXEL_RESOLUTION_Y", float) = 72
		color_range_h_min ("Min H", Range(0.0, 1.0) ) = 0.0
		color_range_h_max ("Max H", Range(0.0, 1.0) ) = 1.0
		color_range_s_min ("Min S", Range(0.0, 1.0) ) = 0.0
		color_range_s_max ("Max S", Range(0.0, 1.0) ) = 1.0
		color_range_v_min ("Min V", Range(0.0, 1.0) ) = 0.0
		color_range_v_max ("Max V", Range(0.0, 1.0) ) = 1.0
		use_edge_detection ("Use edge detection", int) = 1
		edge_threshold ("edge_threshold", Range(0.0, 1.0)) = 0.0
		edge_color ("edge_color", Color) = (0.0, 0.0, 0.0)
		use_color_palette ("Use palette", int) = 0
    }
    SubShader
    {
        // No culling or depth
        // Cull Off ZWrite Off ZTest Always

        Pass
        {
            GLSLPROGRAM

            #include "UnityCG.glslinc"
            
            uniform sampler2D _MainTex;
			uniform sampler2D _CameraDepthTexture;
			//uniform sampler2D _CameraGBufferTexture;

			uniform float color_step = 5; // how many color step do you want?
			uniform float color_range_h_min = 0.0;
			uniform float color_range_h_max = 1.0;
			uniform float color_range_s_min = 0.0;
			uniform float color_range_s_max = 1.0;
			uniform float color_range_v_min = 0.0;
			uniform float color_range_v_max = 1.0;

			uniform float minVal = 1.0;

			uniform int use_edge_detection = 1;
			uniform float edge_threshold = 0.0;
			uniform vec3 edge_color = vec3(0.25);

			uniform int use_color_palette = 0;
			uniform int palette_color_number = 0;
			uniform vec3 palette_color[16];

            out vec4 textureCoordinates;
			vec4 iResolution = _ScreenParams;

			// Pixelate variables
			uniform float PIXEL_RESOLUTION_X = 128;
			uniform float PIXEL_RESOLUTION_Y = 72;
			const int SAMPLE_PER_PIXEL = 3;

            #ifdef VERTEX // here begins the vertex shader

            void main() // all vertex shaders define a main() function
            {
                textureCoordinates = gl_MultiTexCoord0;

                gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
            }

            #endif // here ends the definition of the vertex shader


            #ifdef FRAGMENT // here begins the fragment shader
			// Sobel filter
			void make_kernel(inout float n[9], sampler2D tex, vec2 coord)
			{

				float w = 1.0 / PIXEL_RESOLUTION_X;
				float h = 1.0 / PIXEL_RESOLUTION_Y;

				n[0] = texture2D(tex, coord + vec2( -w, -h)).r;
				n[1] = texture2D(tex, coord + vec2(0.0, -h)).r;
				n[2] = texture2D(tex, coord + vec2(  w, -h)).r;
				n[3] = texture2D(tex, coord + vec2( -w, 0.0)).r;
				n[4] = texture2D(tex, coord).r;
				n[5] = texture2D(tex, coord + vec2(  w, 0.0)).r;
				n[6] = texture2D(tex, coord + vec2( -w, h)).r;
				n[7] = texture2D(tex, coord + vec2(0.0, h)).r;
				n[8] = texture2D(tex, coord + vec2(  w, h)).r;
			}

			float Sobel(sampler2D tex, vec2 coord) 
			{
				float n[9];
				make_kernel( n, tex, coord);

				float sobel_edge_h = n[2] + (2.0*n[5]) + n[8] - (n[0] + (2.0*n[3]) + n[6]);
				float sobel_edge_v = n[0] + (2.0*n[1]) + n[2] - (n[6] + (2.0*n[7]) + n[8]);
				float sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));

				return sobel;
			}

			// RGB2HSV and HSV2RGB from here: https://gist.github.com/983/e170a24ae8eba2cd174f
			vec3 rgb2hsv(vec3 c)
			{
				vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
				vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

				float d = q.x - min(q.w, q.y);
				float e = 1.0e-10;
				return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}

			vec3 hsv2rgb(vec3 c)
			{
				vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
				vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
				return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
			}
			// End of HSV functions

            void main() // all fragment shaders define a main() function
            {
				vec2 coord = gl_FragCoord.xy / iResolution.xy;
				float grid_step_x = (1 / PIXEL_RESOLUTION_X);
				float grid_step_y = (1 / PIXEL_RESOLUTION_Y);

				int grid_coord_x = int(coord.x / grid_step_x); // find which grid it is in x coordinate
				int grid_coord_y = int(coord.y / grid_step_y); // find which grid it is in y coordinate


				vec2 pixel_sample = vec2((grid_coord_x + 0.5) * grid_step_x, (grid_coord_y + 0.5) * grid_step_y);

				// Pixelate variables:
				vec4 pixelated_val = texture2D(_MainTex, pixel_sample);

				// Simplify color values
				float color_step_value = 1/(color_step);

				// HSV conversion, clamping and back to rgb
				vec3 hsv = rgb2hsv(pixelated_val.rgb);
				float h = int(hsv.r /  color_step_value) * color_step_value;
				h = max(min(h, color_range_h_max), color_range_h_min);
				float s = int(hsv.g /  color_step_value) * color_step_value;
				s = max(min(s, color_range_s_max), color_range_s_min);
				float v = int(hsv.b /  color_step_value) * color_step_value;
				v = max(min(v, color_range_v_max), color_range_v_min);
				vec3 rgb = hsv2rgb(vec3(h, s, v));
				gl_FragColor.rgb = rgb;

				

				// Edge Detection				
				if ( use_edge_detection != 0){
					float edge = Sobel(_CameraDepthTexture, pixel_sample) * edge_threshold;
					edge = min(texture2D(_CameraDepthTexture, pixel_sample).r, edge);

					vec3 final_col = mix(rgb, edge_color, edge);
				
					gl_FragColor.rgb = final_col;
				}
				
				// for debug
				// gl_FragColor = texture2D(_CameraDepthTexture, pixel_sample);
				
				// Color Palette
				if (use_color_palette > 0){
					int closest_index = 0;
					float closest_distance = 9999;
					for (int i=0; i< palette_color_number; i++){
						float current_color_distance = length(gl_FragColor.rgb - palette_color[i].rgb);
						if (current_color_distance < closest_distance){
							closest_index = i;
							closest_distance = current_color_distance;
						}
					}
					gl_FragColor.rgb = palette_color[closest_index].rgb;
				}
				
            }

            #endif // here ends the definition of the fragment shader


            ENDGLSL
        }
    }
}
