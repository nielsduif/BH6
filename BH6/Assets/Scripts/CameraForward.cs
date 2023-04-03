using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraForward : MonoBehaviour
{
    [SerializeField]
    KeyCode forwardKey = KeyCode.Mouse0;

    [SerializeField]
    int speed = 1;

    private void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        if (Input.GetKey(forwardKey))
        {
            MoveForward();
        }
    }

    void MoveForward()
    {
        transform.position += Vector3.forward * Time.deltaTime * speed;
    }
}