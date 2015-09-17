//
//  bgmViewController.m
//  SolarSystem
//
//  Created by BGM on 5/5/14.
//  Copyright (c) 2014 ___BGM___. All rights reserved.
//

#import "bgmViewController.h"
#import <math.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

@interface bgmViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLKMatrix4 _cameraMatrix;
    int _viewType;
    float _earthRotation;
    float _earthIncrement;
    float _plutoRotation;
    float _plutoIncrement;
    float _satelliteRotation;
    float _satelliteIncrement;
    float _eyeX;
    float _eyeY;
    float _eyeZ;
}
@property (strong, nonatomic) EAGLContext *context; //openGL ES에 필요한 자원 관리
@property (strong, nonatomic) GLKBaseEffect *effect; //lighting, model view, shading 기능 구현

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

- (GLKMatrix4)moveEarth:(GLKMatrix4)matrix;
- (GLKMatrix4)moveSatellite:(GLKMatrix4)matrix;
- (GLKMatrix4)movePluto:(GLKMatrix4)matrix;
- (void)drawSolarSystem;
@end

@implementation bgmViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    
    _viewType = 0;
    _earthRotation = 0;
    _earthIncrement = 1.0f;
    _plutoRotation = 0;
    _plutoIncrement = 0.25f;
    _satelliteRotation = 0;
    _satelliteIncrement = 2.0f;
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (IBAction)chagneView:(UIButton *)sender {
    _viewType = (_viewType+1)%5;
}

- (IBAction)earthSpeed:(UISlider *)sender {
    if([sender value] <= 0.5f)
        _earthIncrement = 0.5f + 1.0f*[sender value];
    else
        _earthIncrement = 2.0f*[sender value];
}

- (IBAction)satelliteSpeed:(UISlider *)sender {
    if([sender value] <= 0.5f)
        _satelliteIncrement = 0.5f + 1.0f*[sender value];
    else
        _satelliteIncrement = 2.0f*[sender value];
}

- (IBAction)plutoSpeed:(UISlider *)sender {
    if([sender value] <= 0.5f)
        _plutoIncrement = 0.125f + 0.25f*[sender value];
    else
        _plutoIncrement = 0.5f*[sender value];
}



- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context]; //현재 사용할 context등록
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init]; //사용할 광원의 속성값 설정
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer); //buffer object의 이름 생성
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer); //buffer object의 이름으로 메모리에 buffer공간을 생성
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW); //buffer공간에 데이터 입력(큐브)
    
    //큐브를 표현하는 데이터에서 position과 normal속성이 위치한 offset명시
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update //프레임이 갱신되기 전에 호출되어 정보를 업데이트한다.
{
    _earthRotation += self.timeSinceLastUpdate * _earthIncrement;
    _plutoRotation += self.timeSinceLastUpdate * _plutoIncrement;
    _satelliteRotation += self.timeSinceLastUpdate * _satelliteIncrement;
}

- (GLKMatrix4)moveEarth:(GLKMatrix4)matrix
{
    GLKMatrix4 modelViewMatrix = matrix;
    //자전
    GLKMatrix4 baseModelViewMatrix1 = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    baseModelViewMatrix1 = GLKMatrix4Rotate(baseModelViewMatrix1, GLKMathDegreesToRadians(15.0f), 0.0f, 1.0f, 0.0f);
    baseModelViewMatrix1 = GLKMatrix4Rotate(baseModelViewMatrix1, _earthRotation*4, 0.0f, 0.0f, 1.0f);
    //공전
    GLKMatrix4 baseModelViewMatrix2 = GLKMatrix4MakeTranslation(3*cosf(_earthRotation), 3*sinf(_earthRotation), 0.0f);
    //병합
    baseModelViewMatrix1 = GLKMatrix4Multiply(baseModelViewMatrix2, baseModelViewMatrix1);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix1, modelViewMatrix);
    modelViewMatrix = GLKMatrix4Multiply(_cameraMatrix, modelViewMatrix);
    
    return modelViewMatrix;
}

- (GLKMatrix4)moveSatellite:(GLKMatrix4)matrix
{
    GLKMatrix4 modelViewMatrix = matrix;
    //지구 공전
    GLKMatrix4 baseModelViewMatrix1 = GLKMatrix4MakeTranslation(0.0f, 1.5f, 0.0f);
    GLKMatrix4 baseModelViewMatrix2 = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    baseModelViewMatrix2 = GLKMatrix4Rotate(baseModelViewMatrix2, GLKMathDegreesToRadians(15.0f), 0.0f, 1.0f, 0.0f);
    baseModelViewMatrix2 = GLKMatrix4Rotate(baseModelViewMatrix2, _satelliteRotation, 0.0f, 1.0f, 0.0f);
    baseModelViewMatrix2 = GLKMatrix4Rotate(baseModelViewMatrix2, _satelliteRotation*6, 0.0f, 0.0f, 1.0f);
    //태양 공전
    GLKMatrix4 baseModelViewMatrix3 = GLKMatrix4MakeTranslation(3*cosf(_earthRotation), 3*sinf(_earthRotation), 0.0f);
    //병합
    baseModelViewMatrix2 = GLKMatrix4Multiply(baseModelViewMatrix3, baseModelViewMatrix2);
    baseModelViewMatrix1 = GLKMatrix4Multiply(baseModelViewMatrix2, baseModelViewMatrix1);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix1, modelViewMatrix);
    modelViewMatrix = GLKMatrix4Multiply(_cameraMatrix, modelViewMatrix);
    
    return modelViewMatrix;
}

- (GLKMatrix4)movePluto:(GLKMatrix4)matrix
{
    GLKMatrix4 modelViewMatrix = matrix;
    //자전
    GLKMatrix4 baseModelViewMatrix1 = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    baseModelViewMatrix1 = GLKMatrix4Rotate(baseModelViewMatrix1, _plutoRotation*8, 0.0f, 0.0f, 1.0f);
    //공전
    GLKMatrix4 baseModelViewMatrix2 = GLKMatrix4MakeTranslation(7*cos(_plutoRotation), 5*sin(_plutoRotation), 0.0f);
    //병합
    baseModelViewMatrix1 = GLKMatrix4Multiply(baseModelViewMatrix2, baseModelViewMatrix1);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix1, modelViewMatrix);
    modelViewMatrix = GLKMatrix4Multiply(_cameraMatrix, modelViewMatrix);
    
    return modelViewMatrix;
}

- (void)drawSolarSystem
{
    float aspect = fabsf(self.view.bounds.size.width/self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 150.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    //x축
    self.effect.material.diffuseColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f);
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 2.0f, 0.1f, 0.1f);
    self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(_cameraMatrix, modelViewMatrix);//태양 x축
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    self.effect.transform.modelviewMatrix = [self moveEarth:(modelViewMatrix)]; //지구 x축
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    self.effect.transform.modelviewMatrix = [self movePluto:(modelViewMatrix)];//명왕성 x축
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.5f, 1.0f, 1.0f); //위성 x축
    self.effect.transform.modelviewMatrix = [self moveSatellite:(modelViewMatrix)];
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    //y축
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.1f, 2.0f, 0.1f);
    self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(_cameraMatrix, modelViewMatrix);//태양 y축
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    self.effect.transform.modelviewMatrix = [self moveEarth:(modelViewMatrix)]; //지구 y축
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    self.effect.transform.modelviewMatrix = [self movePluto:(modelViewMatrix)];//명왕성 y축
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 1.0f, 0.5f, 1.0f); //위성 y축
    self.effect.transform.modelviewMatrix = [self moveSatellite:(modelViewMatrix)];
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    //z축
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.1f, 0.1f, 2.0f);
    self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(_cameraMatrix, modelViewMatrix);//태양 z축
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    self.effect.transform.modelviewMatrix = [self moveEarth:(modelViewMatrix)]; //지구 z축
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    self.effect.transform.modelviewMatrix = [self movePluto:(modelViewMatrix)];//명왕성 z축
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 1.0f, 1.0f, 0.5f); //위성 z축
    self.effect.transform.modelviewMatrix = [self moveSatellite:(modelViewMatrix)];
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    //태양
    self.effect.material.diffuseColor = GLKVector4Make(0.8f, 0.0f, 0.0f, 1.0f);
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Multiply(_cameraMatrix, modelViewMatrix);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    //지구
    self.effect.material.diffuseColor = GLKVector4Make(0.0f, 0.0f, 0.8f, 1.0f);
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = [self moveEarth:(modelViewMatrix)];
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    //위성
    self.effect.material.diffuseColor = GLKVector4Make(0.0f, 0.8f, 0.0f, 1.0f);
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.5f, 0.5f, 0.5f);
    modelViewMatrix = [self moveSatellite:(modelViewMatrix)];
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    //명왕성
    self.effect.material.diffuseColor = GLKVector4Make(0.8f, 0.8f, 0.0f, 1.0f);
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    modelViewMatrix = [self movePluto:(modelViewMatrix)];
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    GLKMatrix4 allCam = GLKMatrix4MakeLookAt(0.0f, 0.0f, 20.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
    GLKMatrix4 sunCam = GLKMatrix4MakeLookAt(0.0f, 1.0f, 0.0f, 0.0f, 4.0f, 0.0f, 0.0f, 0.0f, 1.0f);
    GLKMatrix4 earthCam = GLKMatrix4MakeLookAt(3*cosf(_earthRotation)+cosf(_earthRotation*6), 3*sinf(_earthRotation)+sinf(_earthRotation*6), 0.0f, 3*cosf(_earthRotation)+4*cosf(_earthRotation*6), 3*sinf(_earthRotation)+4*sinf(_earthRotation*6), 0.0f, 0.0f, 0.0f, 1.0f);
    GLKMatrix4 plutoCam = GLKMatrix4MakeLookAt(6.0f*cos(_plutoRotation), 4.0f*sin(_plutoRotation), 0, 3*cos(_earthRotation), 3*sin(_earthRotation), 0, 0, 0, 1);

    if(_viewType == 0)
    {
        glViewport(0, self.view.window.screen.scale*view.frame.size.height/2, self.view.window.screen.scale*view.frame.size.width/2, self.view.window.screen.scale*view.frame.size.height/2);
        _cameraMatrix = allCam;
        [self drawSolarSystem];
        
        glViewport(self.view.window.screen.scale*view.frame.size.width/2, self.view.window.screen.scale*view.frame.size.height/2, self.view.window.screen.scale*view.frame.size.width/2, self.view.window.screen.scale*view.frame.size.height/2);
        _cameraMatrix = sunCam;
        [self drawSolarSystem];
        
        glViewport(0, 0, self.view.window.screen.scale*view.frame.size.width/2, self.view.window.screen.scale*view.frame.size.height/2);
        _cameraMatrix = earthCam;
        [self drawSolarSystem];
        
        glViewport(self.view.window.screen.scale*view.frame.size.width/2, 0, self.view.window.screen.scale*view.frame.size.width/2, self.view.window.screen.scale*view.frame.size.height/2);
        _cameraMatrix = plutoCam;
        [self drawSolarSystem];
        
    }
    else if(_viewType == 1)
    {
        glViewport(0, 0, self.view.window.screen.scale*view.frame.size.width, self.view.window.screen.scale*view.frame.size.height);
        _cameraMatrix = allCam;
        [self drawSolarSystem];
    }
    else if(_viewType == 2)
    {
        glViewport(0, 0, self.view.window.screen.scale*view.frame.size.width, self.view.window.screen.scale*view.frame.size.height);
        _cameraMatrix = sunCam;
        [self drawSolarSystem];
    }
    else if(_viewType == 3)
    {
        glViewport(0, 0, self.view.window.screen.scale*view.frame.size.width, self.view.window.screen.scale*view.frame.size.height);
        _cameraMatrix = earthCam;
        [self drawSolarSystem];
    }
    else if(_viewType == 4)
    {
        glViewport(0, 0, self.view.window.screen.scale*view.frame.size.width, self.view.window.screen.scale*view.frame.size.height);
        _cameraMatrix = plutoCam;
        [self drawSolarSystem];
    }
    
    //glDrawArrays(GL_TRIANGLES, 0, 36); //vertex buffer에 저장한 큐브를 그린다.
    
    /*
    // Render the object again with ES2
    //쉐이더 프로그램 등록
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);//vertex shader에서 modelViewProjectionMatrix를 설정
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);//vertex shader에 normal matrix를 설정
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
     */
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
