using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MandelbrotMovement : MonoBehaviour
{
    Renderer rend;
    Material mat;
    [SerializeField]
    int iterations;
    [SerializeField]
    KeyCode up = KeyCode.W, down = KeyCode.S, left = KeyCode.A, right = KeyCode.D, zoomIn = KeyCode.E, zoomOut = KeyCode.Q;
    Vector2 pos;
    float scale;
    float moveSpeed = .01f;

    Vector2 smoothPos;
    float smoothScale;

    void Start()
    {
        rend = GetComponent<Renderer>();
        mat = rend.material;

        Vector4 shaderPosScale = mat.GetVector("_Area");
        pos = new Vector2(shaderPosScale.x, shaderPosScale.y);
        scale = shaderPosScale.z;
        mat.SetInt("_Iterations", iterations);
    }

    void FixedUpdate()
    {
        InputHandler();
        mat.SetVector("_Area", new Vector4(smoothPos.x, smoothPos.y, smoothScale, smoothScale));
    }

    void InputHandler()
    {
        if (Input.GetKey(up))
        {
            pos.y += moveSpeed * smoothScale;
        }
        if (Input.GetKey(down))
        {
            pos.y -= moveSpeed * smoothScale;
        }
        if (Input.GetKey(left))
        {
            pos.x -= moveSpeed * smoothScale;
        }
        if (Input.GetKey(right))
        {
            pos.x += moveSpeed * smoothScale;
        }
        if (Input.GetKey(zoomIn))
        {
            scale *= (1 - moveSpeed);
        }
        if (Input.GetKey(zoomOut))
        {
            scale *= (1 + moveSpeed);
        }

        smoothPos = Vector2.Lerp(smoothPos, pos, moveSpeed);
        smoothScale = Mathf.Lerp(smoothScale, scale, moveSpeed);
    }
}