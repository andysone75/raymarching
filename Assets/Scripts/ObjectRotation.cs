using UnityEngine;

public class ObjectRotation : MonoBehaviour
{
    private Vector3 localEulerAngles;
    [Range(0,100)]
    public float speed = 0f;

    private void Start()
    {
        localEulerAngles = transform.localEulerAngles;
    }

    void Update()
    {
        localEulerAngles.y += speed * Time.deltaTime;
        transform.localEulerAngles = localEulerAngles;
    }
}
