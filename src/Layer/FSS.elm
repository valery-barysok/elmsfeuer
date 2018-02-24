module Layer.FSS exposing
    ( Config
    , Mesh
    , SerializedScene
    , makeEntity
    , build
    , init
    )

import Math.Vector3 as Vec3 exposing (vec3, Vec3)
import Math.Vector4 as Vec4 exposing (vec4, Vec4)
import WebGL
import WebGL.Settings exposing (Setting)

import Viewport exposing (Viewport)


type alias Config = {}


type alias Mesh = WebGL.Mesh Vertex


-- Serialization

type alias SColor =
    { rgba : List Float
    , hex : String
    , opacity : Float
    }


type alias SLight =
    { ambient : SColor
    , diffuse : SColor
    , position : List Float
    , ray : List Float
    }



type alias SMaterial =
    { ambient : SColor
    , diffuse : SColor
    , slave : SColor
    }


type alias SPlane =
    { width : Int
    , height : Int
    , triangles : List STriangle
    , vertices : List SVertex
    }


type alias STriangle =
    { a : SVertex
    , b : SVertex
    , c : SVertex
    , centroid : List Float
    , color : SColor
    , normal : List Float
    , u : List Float
    , v : List Float
    , vertices : List SVertex
    }


type alias SVertex =
    { position : List Float
    }


type alias SMesh =
    { geometry : SPlane
    , material : SMaterial
    , position : List Float
    , side : Int
    }

type alias SerializedScene =
    { lights : List SLight
    , meshes : List SMesh
    }



-- Base logic

init : Config
init = {}


makeEntity : Viewport {} -> List Setting -> Mesh -> WebGL.Entity
makeEntity viewport settings mesh =
    WebGL.entityWith
        settings
        vertexShader
        fragmentShader
        mesh
        (uniforms viewport)



-- Mesh


type alias Vertex =
    { aAmbient : Vec4
    , aCentroid : Vec3
    , aDiffuse : Vec4
    , aNormal : Vec3
    , aPosition : Vec3
    , aSide : Float
    }


build : Config -> Mesh
build config =
    WebGL.triangles
        [
        ]



-- Shaders


type alias Uniforms =
    Viewport
        { uLightAmbient : Vec4
        , uLightDiffuse : Vec4
        , uLightPosition : Vec3
        , uResolution : Vec3
        }


uniforms : Viewport {} -> Uniforms
uniforms v =
    -- { perspective = Mat4.mul v.perspective v.camera }
    { uLightAmbient = vec4 0 0 0 0
    , uLightDiffuse = vec4 0 0 0 0
    , uLightPosition = vec3 0 0 0
    , uResolution = vec3 0 0 0

    , rotation = v.rotation
    , perspective = v.perspective
    , camera = v.camera
    --, shade = 0.8
    , cameraTranslate = v.cameraTranslate
    , cameraRotate = v.cameraRotate
    }


vertexShader : WebGL.Shader Vertex Uniforms { vColor : Vec4 }
vertexShader =
    [glsl|

        // Precision
        precision mediump float;

        // Lights
        //#define LIGHTS + lights

        // Attributes
        attribute float aSide;
        attribute vec3 aPosition;
        attribute vec3 aCentroid;
        attribute vec3 aNormal;
        attribute vec4 aAmbient;
        attribute vec4 aDiffuse;

        // Uniforms
        uniform vec3 uResolution;
        uniform vec3 uLightPosition[LIGHTS];
        uniform vec4 uLightAmbient[LIGHTS];
        uniform vec4 uLightDiffuse[LIGHTS];

        // Varyings
        varying vec4 vColor;

        // Main
        void main() {

            // Create color
            vColor = vec4(0.0);

            // Calculate the vertex position
            vec3 position = aPosition / uResolution * 2.0;

            // Iterate through lights
            for (int i = 0; i < LIGHTS; i++) {
                vec3 lightPosition = uLightPosition[i];
                vec4 lightAmbient = uLightAmbient[i];
                vec4 lightDiffuse = uLightDiffuse[i];

                // Calculate illuminance
                vec3 ray = normalize(lightPosition - aCentroid);
                float illuminance = dot(aNormal, ray);
                if (aSide == 0.0) {
                    illuminance = max(illuminance, 0.0);
                } else if (aSide == 1.0) {
                    illuminance = abs(min(illuminance, 0.0));
                } else if (aSide == 2.0) {
                    illuminance = max(abs(illuminance), 0.0);
                }

                // Calculate ambient light
                vColor += aAmbient * lightAmbient;

                // Calculate diffuse light
                vColor += aDiffuse * lightDiffuse * illuminance;
            }

            // Clamp color
            vColor = clamp(vColor, 0.0, 1.0);

            // Set gl_Position
            gl_Position = vec4(position, 1.0);

        }

    |]


-- vertexShader : WebGL.Shader Vertex Uniforms { vcolor : Vec3 }
-- vertexShader =
--     [glsl|

--         attribute vec3 position;
--         attribute vec3 color;

--         uniform mat4 cameraTranslate;
--         uniform mat4 cameraRotate;
--         uniform mat4 perspective;
--         uniform mat4 camera;
--         uniform mat4 rotation;

--         varying vec3 vcolor;

--         void main () {
--             // gl_Position = perspective * camera * rotation * cameraTranslate * cameraRotate * vec4(position, 1.0);
--             // gl_Position = perspective * camera * rotation * vec4(position, 1.0);
--             gl_Position = perspective * camera * rotation * vec4(position, 1.0);
--             vcolor = color;
--         }

--     |]


fragmentShader : WebGL.Shader {} Uniforms { vColor : Vec4 }
fragmentShader =
    [glsl|

        // Precision
        precision mediump float;

        // Varyings
        varying vec4 vColor;

        // Main
        void main() {

            // Set gl_FragColor
            gl_FragColor = vColor;

        }

    |]