attribute vec4 vPosition;
attribute vec4 vSourceColor;
uniform mat4 projection;
uniform mat4 modelView;

varying vec4 vDestinationColor;

void main(void) {
    vDestinationColor = vSourceColor;
    gl_Position = projection * modelView * vPosition;
}