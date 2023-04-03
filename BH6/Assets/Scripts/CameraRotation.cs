using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraRotation : MonoBehaviour
{
    void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
    }

    // Update is called once per frame
    void Update()
    {
        float mouseX = Input.GetAxis("Mouse X");
        float mouseY = Input.GetAxis("Mouse Y");

        Vector3 currentRot = transform.localEulerAngles;
        currentRot.y += mouseX;
        currentRot.x -= mouseY;

        transform.localRotation = Quaternion.Euler(currentRot);
    }
}
