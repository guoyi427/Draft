attribute vec4 vPosition;
uniform mat4 projection;
uniform mat4 modelView;

attribute vec4 vSourceColor;
varying vec4 DestinationColor;

void main(void) {
    gl_Position = projection * modelView * vPosition;
    DestinationColor = vSourceColor;
}