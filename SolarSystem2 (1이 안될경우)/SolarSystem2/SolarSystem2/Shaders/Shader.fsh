//
//  Shader.fsh
//  SolarSystem2
//
//  Created by ip_19 on 14. 5. 13..
//  Copyright (c) 2014년 visbic. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
