﻿using UnityEngine;

public class GameHandler : MonoBehaviour
{
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            ScreenshotHandler.TakeScreenshot_Static(1080, 1920);
        }
    }
}