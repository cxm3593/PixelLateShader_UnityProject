using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotationScript : MonoBehaviour
{
    public float rotation_rate = 35.0f;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(Time.deltaTime * rotation_rate, Time.deltaTime * rotation_rate, Time.deltaTime * rotation_rate, Space.World);
    }
}
