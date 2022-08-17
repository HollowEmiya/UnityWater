using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectInWater : MonoBehaviour
{
    [SerializeField]
    float height = 0.1f;
    float period = 1;

    private Vector3 initialPosition;
    private float offset;

    private void Awake()
    {
        initialPosition = transform.position;

        offset = 1 - (Random.value * 2);
    }

    // Update is called once per frame
    void Update()
    {
        transform.position = initialPosition - Vector3.up * Mathf.Sin((Time.time + offset) * period) * height;
    }
}
