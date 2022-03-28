Shader "Hidden/GLSL_PP"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		color_step ("ColorStep", float) = 5 
		PIXEL_RESOLUTION_X ("PIXEL_RESOLUTION_X", float) = 128
		PIXEL_RESOLUTION_Y ("PIXEL_RESOLUTION_Y", float) = 72
		color_range_r_min ("color_range_r_min", Range(0.0, 1.0) ) = 0.0
		color_range_r_max ("color_range_r_max", Range(0.0, 1.0) ) = 1.0
		color_range_g_min ("color_range_g_min", Range(0.0, 1.0) ) = 0.0
		color_range_g_max ("color_range_g_max", Range(0.0, 1.0) ) = 1.0
		color_range_b_min ("color_range_b_min", Range(0.0, 1.0) ) = 0.0
		color_range_b_max ("color_range_b_max", Range(0.0, 1.0) ) = 1.0
		edge_threshold ("edge_threshold", Range(0.0, 1.0)) = 0.0
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
			uniform float color_range_r_min = 0.0;
			uniform float color_range_r_max = 1.0;
			uniform float color_range_g_min = 0.0;
			uniform float color_range_g_max = 1.0;
			uniform float color_range_b_min = 0.0;
			uniform float color_range_b_max = 1.0;

			uniform float  edge_threshold = 0.0;



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
            //in vec4 textureCoordinates;

			

			float findMedian(float[9] channel_values){
				for(int i=1;i<9;i++){
					float value = channel_values[i];
					int j=i-1;
					while(j>=0 && channel_values[j] > value){
						channel_values[j+1] = channel_values[j];
						j = j-1;
					}
					channel_values[j+1] = value;
				}
				return channel_values[4];
			}

			void median_filter(int grid_coord_x, int grid_coord_y, float grid_step_x, float grid_step_y){
				// Get neighbor color samples:
				vec4 color1 = texture2D(_MainTex, vec2((grid_coord_x-0.5)*grid_step_x, (grid_coord_y-0.5)*grid_coord_y) );
				vec4 color2 = texture2D(_MainTex, vec2((grid_coord_x+0.5)*grid_step_x, (grid_coord_y-0.5)*grid_coord_y) );
				vec4 color3 = texture2D(_MainTex, vec2((grid_coord_x+1.5)*grid_step_x, (grid_coord_y-0.5)*grid_coord_y) );
				vec4 color4 = texture2D(_MainTex, vec2((grid_coord_x-0.5)*grid_step_x, (grid_coord_y+0.5)*grid_coord_y) );
				vec4 color5 = gl_FragColor;
				vec4 color6 = texture2D(_MainTex, vec2((grid_coord_x+1.5)*grid_step_x, (grid_coord_y+0.5)*grid_coord_y) );
				vec4 color7 = texture2D(_MainTex, vec2((grid_coord_x-0.5)*grid_step_x, (grid_coord_y+1.5)*grid_coord_y) );
				vec4 color8 = texture2D(_MainTex, vec2((grid_coord_x+0.5)*grid_step_x, (grid_coord_y+1.5)*grid_coord_y) );
				vec4 color9 = texture2D(_MainTex, vec2((grid_coord_x+1.5)*grid_step_x, (grid_coord_y+1.5)*grid_coord_y) );

				float r_array[9] = {color1.r, color2.r, color3.r, color4.r, color5.r, color6.r, color7.r, color8.r, color9.r};
				float r_median = findMedian(r_array);
				gl_FragColor.r = (r_median + gl_FragColor.r) / float(2);
				//gl_FragColor.r = r_median;

				float g_array[9] = {color1.g, color2.g, color3.g, color4.g, color5.g, color6.g, color7.g, color8.g, color9.g};
				float g_median = findMedian(g_array);
				gl_FragColor.g = (g_median + gl_FragColor.g) / float(2);
				//gl_FragColor.g = g_median;

				float b_array[9] = {color1.b, color2.b, color3.b, color4.b, color5.b, color6.b, color7.b, color8.b, color9.b};
				float b_median = findMedian(b_array);
				gl_FragColor.b = (b_median + gl_FragColor.b) / float(2);
				//gl_FragColor.b = b_median;
			}

			void depthDetection(int grid_coord_x, int grid_coord_y, float grid_step_x, float grid_step_y){
				// A very basic version of edge detection
				vec4 color1 = texture2D(_CameraDepthTexture, vec2((grid_coord_x-0.5)*grid_step_x, (grid_coord_y-0.5)*grid_coord_y) );
				vec4 color2 = texture2D(_CameraDepthTexture, vec2((grid_coord_x+0.5)*grid_step_x, (grid_coord_y-0.5)*grid_coord_y) );
				vec4 color3 = texture2D(_CameraDepthTexture, vec2((grid_coord_x+1.5)*grid_step_x, (grid_coord_y-0.5)*grid_coord_y) );
				vec4 color4 = texture2D(_CameraDepthTexture, vec2((grid_coord_x-0.5)*grid_step_x, (grid_coord_y+0.5)*grid_coord_y) );
				vec4 color5 = gl_FragColor;
				vec4 color6 = texture2D(_CameraDepthTexture, vec2((grid_coord_x+1.5)*grid_step_x, (grid_coord_y+0.5)*grid_coord_y) );
				vec4 color7 = texture2D(_CameraDepthTexture, vec2((grid_coord_x-0.5)*grid_step_x, (grid_coord_y+1.5)*grid_coord_y) );
				vec4 color8 = texture2D(_CameraDepthTexture, vec2((grid_coord_x+0.5)*grid_step_x, (grid_coord_y+1.5)*grid_coord_y) );
				vec4 color9 = texture2D(_CameraDepthTexture, vec2((grid_coord_x+1.5)*grid_step_x, (grid_coord_y+1.5)*grid_coord_y) );
				// These colors will only have r channel values for depth value
				float this_depth = color5.r;
				//float edge_threshold = 0.5;
				if ((color2.r - this_depth) > edge_threshold || (color4.r - this_depth) > edge_threshold || (color6.r - this_depth) > edge_threshold || (color8.r - this_depth) > edge_threshold){
					gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
				}
			}

            void main() // all fragment shaders define a main() function
            {
				vec2 coord = gl_FragCoord.xy / iResolution.xy;
				float grid_step_x = (1 / PIXEL_RESOLUTION_X);
				float grid_step_y = (1 / PIXEL_RESOLUTION_Y);

				int grid_coord_x = int(coord.x / grid_step_x); // find which grid it is in x coordinate
				int grid_coord_y = int(coord.y / grid_step_y); // find which grid it is in y coordinate


				vec2 pixel_sample = vec2((grid_coord_x + 0.5) * grid_step_x, (grid_coord_y + 0.5) * grid_step_y);

				// Pixelate variables:
				gl_FragColor = texture2D(_MainTex, pixel_sample);

				// Median filter result:
				//median_filter(grid_coord_x, grid_coord_y, grid_step_x, grid_step_y);

				// Edge Detection
				depthDetection(grid_coord_x, grid_coord_y, grid_step_x, grid_step_y);

				// Simplify color values
				float color_step_value = 1/(color_step);
				gl_FragColor.r = int(gl_FragColor.r /  color_step_value) * color_step_value;
				gl_FragColor.r = max(min(gl_FragColor.r, color_range_r_max), color_range_r_min);
				gl_FragColor.g = int(gl_FragColor.g /  color_step_value) * color_step_value;
				gl_FragColor.g = max(min(gl_FragColor.g, color_range_g_max), color_range_g_min);
				gl_FragColor.b = int(gl_FragColor.b /  color_step_value) * color_step_value;
				gl_FragColor.b = max(min(gl_FragColor.b, color_range_b_max), color_range_b_min);
				
				// for debug
				//gl_FragColor = texture2D(_CameraDepthTexture, coord);
				
				
            }

            #endif // here ends the definition of the fragment shader


            ENDGLSL
        }
    }
}
