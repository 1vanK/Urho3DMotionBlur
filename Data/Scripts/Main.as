Scene@ scene_;
float yaw = -90.0f;
float pitch;
Node@ cameraNode;
Camera@ camera;

// Храним матрицу предыдущего кадра.
Matrix4 oldViewProj;

void Start()
{
    scene_ = Scene();
    scene_.LoadXML(cache.GetFile("Scenes/Room.xml"));
    
    cameraNode = scene_.CreateChild();
    camera = cameraNode.CreateComponent("Camera");
    cameraNode.position = Vector3(15.0f, 10.0f, 0.0f);
    camera.fov = 70.0f;
    
    Node@ weaponNode = cameraNode.CreateChild();
    weaponNode.Scale(0.1f);
    weaponNode.position = Vector3(0.7f, -1.3f, 1.2f);
    StaticModel@ weaponObject = weaponNode.CreateComponent("StaticModel");
    weaponObject.model = cache.GetResource("Model", "Models/weapon.mdl");
    weaponObject.ApplyMaterialList();
    
    renderer.SetDefaultRenderPath(cache.GetResource("XMLFile", "RenderPaths/MyForwardHWDepth.xml"));
    Viewport@ viewport = Viewport(scene_, camera);
    renderer.viewports[0] = viewport;

    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("RenderUpdate", "HandleRenderUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
   
    float timeStep = eventData["TimeStep"].GetFloat();

    IntVector2 mouseMove = input.mouseMove;
    const float MOVE_SPEED = 20.0f;
    const float MOUSE_SENSITIVITY = 0.1f;
    yaw += MOUSE_SENSITIVITY * mouseMove.x;
    pitch += MOUSE_SENSITIVITY * mouseMove.y;
    pitch = Clamp(pitch, -90.0f, 90.0f);
    cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);

    if (input.keyDown['W'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, 1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['S'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, -1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['A'])
        cameraNode.Translate(Vector3(-1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['D'])
        cameraNode.Translate(Vector3(1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
    
    if (input.keyDown[KEY_ESC])
        engine.Exit();
        
    // Замедляем программу, чтобы посмотреть, как шейдер себя ведет при низком ФПС.
    /*for (int i = 0; i < 10000; i++)
    {
        for (int j = 0; j < 900; j++)
        {
            i * j;
        }
    }*/
}

// Последнее событие перед рендерингом.
void HandleRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();

    RenderPath@ renderPath = renderer.viewports[0].renderPath;
    renderPath.shaderParameters["OldViewProj"] = Variant(oldViewProj);
    renderPath.shaderParameters["TimeStep"] = Variant(timeStep);
}

// Событие после рендеринга.
void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    oldViewProj = camera.projection * camera.view;
}
