using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraForward : MonoBehaviour
{
    [SerializeField]
    KeyCode forwardKey = KeyCode.Mouse0, backwardKey = KeyCode.Mouse1;

    [SerializeField]
    float speed = 1;

    void Update()
    {
        Vector3 _dir = Input.GetKey(forwardKey) ? transform.forward : Input.GetKey(backwardKey) ? -transform.forward : Vector3.zero;
        MoveForward(_dir);
    }

    void MoveForward(Vector3 _dir)
    {
        transform.localPosition += _dir * Time.deltaTime * speed;
    }
}