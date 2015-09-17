//
//  Shader.fsh
//  SolarSystem
//
//  Created by BGM on 5/5/14.
//  Copyright (c) 2014 ___BGM___. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
