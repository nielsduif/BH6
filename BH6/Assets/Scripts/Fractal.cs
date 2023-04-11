using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Fractal : MonoBehaviour
{
    [SerializeField]
    float childScale = .5f;

    [SerializeField]
    int maxDepth = 4;
    int depth;

    [SerializeField]
    Material material;
    Material[] materials;

    [SerializeField]
    Mesh[] meshes;

    [SerializeField]
    float spawnProb = .7f;

    [SerializeField]
    float maxRotationSpeed = 60;
    float rotationSpeed;

    [SerializeField]
    float maxTwist = 20;

    static Vector3[] childDir =
    {
        Vector3.up,
        Vector3.right,
        Vector3.left,
        Vector3.forward,
        Vector3.back
    };

    static Quaternion[] childOri =
    {
        Quaternion.identity,
        Quaternion.Euler(0,0,-90),
        Quaternion.Euler(0,0,90),
        Quaternion.Euler(90, 0, 0),
        Quaternion.Euler(-90, 0, 0),
    };

    private void Start()
    {
        rotationSpeed = Random.Range(-maxRotationSpeed, maxRotationSpeed);
        transform.Rotate(Random.Range(-maxTwist, maxTwist), 0, 0);
        if (materials == null)
        {
            InitializeMaterials();
        }
        gameObject.AddComponent<MeshFilter>().mesh = meshes[Random.Range(0, meshes.Length)];
        gameObject.AddComponent<MeshRenderer>().material = materials[depth];
        if (depth < maxDepth)
        {
            CreateChildren();
        }
    }

    private void Update()
    {
        transform.Rotate(0, rotationSpeed * Time.deltaTime, 0);
    }

    void CreateChildren()
    {
        for (int i = 0; i < childDir.Length; i++)
        {
            if (Random.value < spawnProb)
            {
                new GameObject("FC").AddComponent<Fractal>().Instantiate(this, i);
            }
        }
    }

    void Instantiate(Fractal _parent, int _index)
    {
        meshes = _parent.meshes;
        materials = _parent.materials;
        maxDepth = _parent.maxDepth;
        depth = _parent.depth + 1;
        childScale = _parent.childScale;
        transform.parent = _parent.transform;
        spawnProb = _parent.spawnProb;
        maxRotationSpeed = _parent.maxRotationSpeed;
        maxTwist = _parent.maxTwist;
        transform.localScale = Vector3.one * childScale;
        transform.localPosition = childDir[_index] * (.5f + .5f * childScale);
        transform.localRotation = childOri[_index];
    }

    private void InitializeMaterials()
    {
        materials = new Material[maxDepth + 1];
        for (int i = 0; i <= maxDepth; i++)
        {
            float c = (float)i / (maxDepth - 1);
            c *= c;
            materials[i] = new Material(material);
            materials[i].color = Color.Lerp(Color.white, Color.yellow, c);
        }
        materials[maxDepth].color = Color.magenta;
    }
}